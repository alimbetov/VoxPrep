package io.github.alimbetov.voxprep.backend.tts.web;

import io.github.alimbetov.voxprep.backend.asset.application.ObjectStoragePort;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import io.github.alimbetov.voxprep.backend.tts.application.WorkerApiKeyVerifier;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Read-only delivery from completed STAGED bundles, never from Hugging Face.
 * V1 Piper model routes remain unchanged.
 *
 * Currently uses a bounded byte[] read through existing ObjectStoragePort;
 * replace with streaming before supporting artifacts over the cap.
 */
@RestController
@RequestMapping("/internal/v2/tts/bundles")
public class KokoroBundleDeliveryV2Controller {

    private static final long MAX_DELIVERY_BYTES = 256L * 1024 * 1024;

    private final WorkerApiKeyVerifier verifier;
    private final JdbcTemplate jdbc;
    private final FileAssetRepository assets;
    private final ObjectStoragePort storage;

    public KokoroBundleDeliveryV2Controller(
            WorkerApiKeyVerifier verifier,
            JdbcTemplate jdbc,
            FileAssetRepository assets,
            ObjectStoragePort storage) {
        this.verifier = verifier;
        this.jdbc = jdbc;
        this.assets = assets;
        this.storage = storage;
    }

    @GetMapping("/{modelCode}")
    public ResponseEntity<BundleInfo> manifest(
            @RequestHeader(name = HttpHeaders.AUTHORIZATION, required = false) String authorization,
            @PathVariable String modelCode) {
        if (!kokoroIdentity(authorization)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        var bundles = jdbc.query("""
                SELECT id, model_code, source_repository, source_revision,
                       manifest_sha256, license_name, license_reference
                  FROM app.tts_kokoro_bundle
                 WHERE model_code = ? AND status = 'STAGED'
                """, (rs, index) -> new BundleInfo(
                    rs.getObject("id", UUID.class),
                    rs.getString("model_code"),
                    rs.getString("source_repository"),
                    rs.getString("source_revision"),
                    rs.getString("manifest_sha256"),
                    rs.getString("license_name"),
                    rs.getString("license_reference"), List.of()), modelCode);
        if (bundles.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        var base = bundles.getFirst();
        var entries = jdbc.query("""
                SELECT a.logical_path, a.artifact_role, a.file_asset_id, a.sha256,
                       a.size_bytes, a.media_type
                  FROM app.tts_kokoro_bundle_artifact a
                 WHERE a.bundle_id = ? ORDER BY a.logical_path
                """, (rs, index) -> new ArtifactInfo(
                    rs.getString("logical_path"), rs.getString("artifact_role"),
                    rs.getObject("file_asset_id", UUID.class),
                    rs.getString("sha256"), rs.getLong("size_bytes"),
                    rs.getString("media_type")), base.id());
        if (entries.isEmpty()) {
            return ResponseEntity.status(HttpStatus.CONFLICT).build();
        }
        return ResponseEntity.ok(new BundleInfo(base.id(), base.modelCode(), base.sourceRepository(),
                base.sourceRevision(), base.manifestSha256(), base.licenseName(),
                base.licenseReference(), List.copyOf(entries)));
    }

    @GetMapping("/{modelCode}/artifacts/{assetId}")
    public ResponseEntity<byte[]> artifact(
            @RequestHeader(name = HttpHeaders.AUTHORIZATION, required = false) String authorization,
            @PathVariable String modelCode, @PathVariable UUID assetId) {
        if (!kokoroIdentity(authorization)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        var references = jdbc.query("""
                SELECT a.sha256, a.size_bytes, a.media_type
                  FROM app.tts_kokoro_bundle b
                  JOIN app.tts_kokoro_bundle_artifact a ON a.bundle_id = b.id
                 WHERE b.model_code = ? AND b.status = 'STAGED' AND a.file_asset_id = ?
                """, (rs, index) -> new ArtifactReference(
                    rs.getString("sha256"), rs.getLong("size_bytes"),
                    rs.getString("media_type")), modelCode, assetId);
        if (references.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        var ref = references.getFirst();
        if (ref.sizeBytes() > MAX_DELIVERY_BYTES) {
            return ResponseEntity.status(HttpStatus.PAYLOAD_TOO_LARGE).build();
        }
        var assetOptional = assets.findById(assetId);
        if (assetOptional.isEmpty()) {
            return ResponseEntity.status(HttpStatus.CONFLICT).build();
        }
        var asset = assetOptional.orElseThrow();
        if (asset.getKind() != FileAssetKind.TTS_MODEL || asset.getStatus() != FileAssetStatus.READY
                || asset.getSizeBytes() != ref.sizeBytes()
                || !asset.getSha256().equals(ref.sha256())) {
            return ResponseEntity.status(HttpStatus.CONFLICT).build();
        }
        byte[] bytes = storage.read(asset.getBucket(), asset.getObjectKey());
        if (bytes.length != ref.sizeBytes() || !sha256(bytes).equals(ref.sha256())) {
            return ResponseEntity.status(HttpStatus.CONFLICT).build();
        }
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(ref.mediaType()))
                .header("X-Content-SHA256", ref.sha256())
                .body(bytes);
    }

    private boolean kokoroIdentity(String authorization) {
        return verifier.authenticatedEngine(authorization)
                .filter(engine -> engine == TtsEngine.KOKORO).isPresent();
    }

    private static String sha256(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    public record BundleInfo(
            UUID id, String modelCode, String sourceRepository, String sourceRevision,
            String manifestSha256, String licenseName, String licenseReference,
            List<ArtifactInfo> artifacts) { }

    public record ArtifactInfo(
            String path, String role, UUID assetId, String sha256,
            long sizeBytes, String mediaType) { }

    private record ArtifactReference(String sha256, long sizeBytes, String mediaType) { }
}
