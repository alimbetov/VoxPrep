package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.asset.application.FileAssetIngestService;
import io.github.alimbetov.voxprep.backend.asset.application.ObjectStoragePort;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Backend-only staged Kokoro bundle provisioning. Never enables jobs/voices.
 * Files are fetched from a pinned source, verified, uploaded via the existing
 * FileAsset ingestion path to RustFS, then published atomically into staging.
 */
@Service
public class KokoroBundleProvisioningService {

    private final TtsModelArtifactSource source;
    private final FileAssetIngestService ingest;
    private final FileAssetRepository assets;
    private final ObjectStoragePort storage;
    private final JdbcTemplate jdbc;
    private final TransactionTemplate transactions;
    private final TtsProvisioningLock lock;

    public KokoroBundleProvisioningService(
            TtsModelArtifactSource source,
            FileAssetIngestService ingest,
            FileAssetRepository assets,
            ObjectStoragePort storage,
            JdbcTemplate jdbc,
            TransactionTemplate transactions,
            TtsProvisioningLock lock) {
        this.source = source;
        this.ingest = ingest;
        this.assets = assets;
        this.storage = storage;
        this.jdbc = jdbc;
        this.transactions = transactions;
        this.lock = lock;
    }

    public UUID provision(KokoroProvisioningProperties.Bundle bundle) {
        Objects.requireNonNull(bundle, "bundle");
        String code = required(bundle.getModelCode(), "modelCode", 128);
        if (!code.matches("[a-zA-Z0-9_.-]+")) {
            throw new IllegalArgumentException("Invalid Kokoro modelCode");
        }
        String repo = required(bundle.getSourceRepository(), "sourceRepository", 256);
        if (!repo.matches("[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+")) {
            throw new IllegalArgumentException("Invalid Kokoro repository");
        }
        String revision = required(bundle.getSourceRevision(), "sourceRevision", 128);
        if (!revision.matches("[0-9a-f]{40}")) {
            throw new IllegalArgumentException("Kokoro source revision must be a pinned commit SHA");
        }
        String license = required(bundle.getLicenseName(), "licenseName", 256);
        String licenseReference = required(bundle.getLicenseReference(), "licenseReference", 1024);
        if (!licenseReference.startsWith("https://")) {
            throw new IllegalArgumentException("Kokoro license reference must be HTTPS");
        }
        List<TtsArtifactManifest.Artifact> items = new ArrayList<>();
        if (bundle.getArtifacts() == null) {
            throw new IllegalArgumentException("Kokoro artifacts are required");
        }
        for (KokoroProvisioningProperties.Artifact item : bundle.getArtifacts()) {
            items.add(new TtsArtifactManifest.Artifact(
                    item.getPath(), item.getRole(), item.getSha256(),
                    item.getSizeBytes(), item.getMediaType()));
        }
        var manifest = new TtsArtifactManifest(TtsEngine.KOKORO, revision, items);
        // Freeze and verify configured artifact URLs before touching the network.
        Map<String, KokoroProvisioningProperties.Artifact> configured = new java.util.HashMap<>();
        for (KokoroProvisioningProperties.Artifact item : bundle.getArtifacts()) {
            if (configured.putIfAbsent(item.getPath(), item) != null) {
                throw new IllegalArgumentException("Duplicate Kokoro artifact path");
            }
            String expectedUrl = "https://huggingface.co/" + repo + "/resolve/"
                    + revision + "/" + item.getPath();
            if (!expectedUrl.equals(item.getUrl())) {
                throw new IllegalArgumentException("Kokoro artifact URL is not pinned to manifest");
            }
        }
        return lock.withLock("kokoro:" + code, () -> provisionLocked(
                code, repo, revision, license, licenseReference, manifest, configured));
    }

    private UUID provisionLocked(
            String code, String repo, String revision,
            String license, String licenseReference,
            TtsArtifactManifest manifest,
            Map<String, KokoroProvisioningProperties.Artifact> configured) {
        List<Map<String, Object>> current = jdbc.queryForList(
                "SELECT id, manifest_sha256, source_revision FROM app.tts_kokoro_bundle WHERE model_code = ?",
                code);
        if (!current.isEmpty()) {
            var row = current.getFirst();
            if (!manifest.sha256().equals(row.get("manifest_sha256"))
                    || !revision.equals(row.get("source_revision"))) {
                throw new IllegalStateException("Existing Kokoro bundle has a different immutable revision");
            }
            UUID bundleId = (UUID) row.get("id");
            Integer count = jdbc.queryForObject("""
                    SELECT count(*)
                      FROM app.tts_kokoro_bundle_artifact ba
                      JOIN app.file_asset fa ON fa.id = ba.file_asset_id
                     WHERE ba.bundle_id = ?
                       AND fa.kind = 'TTS_MODEL'
                       AND fa.status = 'READY'
                       AND fa.sha256 = ba.sha256
                       AND fa.size_bytes = ba.size_bytes
                    """, Integer.class, bundleId);
            if (count == null || count != manifest.artifacts().size()) {
                throw new IllegalStateException("Incomplete or damaged staged Kokoro bundle");
            }
            return bundleId;
        }

        List<StoredArtifact> stored = new ArrayList<>();
        for (var artifact : manifest.artifacts()) {
            var item = configured.get(artifact.path());
            var request = new TtsModelArtifactSource.ArtifactRequest(
                    "huggingface", repo, revision, item.getUrl());
            byte[] bytes = source.fetch(request);
            if (bytes.length != artifact.sizeBytes()
                    || !sha256(bytes).equals(artifact.sha256())) {
                throw new IllegalStateException("Kokoro artifact checksum or length mismatch: " + artifact.path());
            }
            String objectKey = "tts/models/kokoro/" + code + "/"
                    + manifest.sha256() + "/" + artifact.path();
            FileAssetEntity storedAsset = assets.findByBucketAndObjectKey(storage.defaultBucket(), objectKey)
                    .orElse(null);
            if (storedAsset == null) {
                storedAsset = ingest.ingest(new FileAssetIngestService.IngestCommand(
                        FileAssetKind.TTS_MODEL, storage.defaultBucket(), objectKey,
                        artifact.mediaType(), Map.of(
                                "source-provider", "huggingface",
                                "source-repository", repo,
                                "source-revision", revision,
                                "manifest-sha256", manifest.sha256()),
                        bytes));
            }
            if (storedAsset.getKind() != FileAssetKind.TTS_MODEL
                    || storedAsset.getStatus() != FileAssetStatus.READY
                    || storedAsset.getSizeBytes() != artifact.sizeBytes()
                    || !storedAsset.getSha256().equals(artifact.sha256())) {
                throw new IllegalStateException("Conflicting staged Kokoro file asset: " + artifact.path());
            }
            stored.add(new StoredArtifact(artifact, storedAsset.getId()));
        }

        return Objects.requireNonNull(transactions.execute(tx -> {
            UUID id = UUID.randomUUID();
            jdbc.update("""
                    INSERT INTO app.tts_kokoro_bundle (
                        id, model_code, manifest_sha256, source_repository,
                        source_revision, license_name, license_reference, status)
                    VALUES (?, ?, ?, ?, ?, ?, ?, 'STAGED')
                    """, id, code, manifest.sha256(), repo, revision, license, licenseReference);
            for (StoredArtifact a : stored) {
                jdbc.update("""
                        INSERT INTO app.tts_kokoro_bundle_artifact (
                            bundle_id, logical_path, artifact_role, file_asset_id,
                            sha256, size_bytes, media_type)
                        VALUES (?, ?, ?, ?, ?, ?, ?)
                        """, id, a.artifact().path(), a.artifact().role(), a.assetId(),
                        a.artifact().sha256(), a.artifact().sizeBytes(), a.artifact().mediaType());
            }
            return id;
        }));
    }

    private static String required(String input, String label, int max) {
        if (input == null || input.isBlank() || !input.equals(input.strip()) || input.length() > max) {
            throw new IllegalArgumentException("Invalid " + label);
        }
        return input;
    }

    private static String sha256(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    private record StoredArtifact(TtsArtifactManifest.Artifact artifact, UUID assetId) { }
}
