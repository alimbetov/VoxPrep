package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.asset.application.FileAssetIngestService;
import io.github.alimbetov.voxprep.backend.asset.application.ObjectStoragePort;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsVoiceModelStatus;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelRepository;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceRepository;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Objects;
import org.springframework.stereotype.Service;

@Service
public class TtsModelMaterializationService {

    private final TtsVoiceRepository voiceRepository;
    private final TtsVoiceModelRepository modelRepository;
    private final FileAssetRepository assetRepository;
    private final FileAssetIngestService ingestService;
    private final ObjectStoragePort objectStorage;
    private final TtsModelArtifactSource artifactSource;

    public TtsModelMaterializationService(
            TtsVoiceRepository voiceRepository,
            TtsVoiceModelRepository modelRepository,
            FileAssetRepository assetRepository,
            FileAssetIngestService ingestService,
            ObjectStoragePort objectStorage,
            TtsModelArtifactSource artifactSource) {
        this.voiceRepository = Objects.requireNonNull(voiceRepository, "voiceRepository");
        this.modelRepository = Objects.requireNonNull(modelRepository, "modelRepository");
        this.assetRepository = Objects.requireNonNull(assetRepository, "assetRepository");
        this.ingestService = Objects.requireNonNull(ingestService, "ingestService");
        this.objectStorage = Objects.requireNonNull(objectStorage, "objectStorage");
        this.artifactSource = Objects.requireNonNull(artifactSource, "artifactSource");
    }

    public TtsVoiceModelEntity materialize(
            TtsModelSelector selector,
            TtsModelCatalogGateway.ModelDescriptor descriptor) {
        Objects.requireNonNull(selector, "selector");
        Objects.requireNonNull(descriptor, "descriptor");

        var existing = modelRepository.findByCode(selector.modelCode());
        if (existing.isPresent()) {
            return existing.orElseThrow();
        }

        var voice = voiceRepository.findByCode(selector.voiceCode())
                .orElseThrow(() -> new NoSuchElementException("TTS voice not found: " + selector.voiceCode()));

        byte[] modelBytes = artifactSource.fetch(request(descriptor, descriptor.modelUrl()));
        byte[] configBytes = artifactSource.fetch(request(descriptor, descriptor.configUrl()));
        verifySha(modelBytes, descriptor.modelSha256(), "model");
        verifySha(configBytes, descriptor.configSha256(), "config");

        FileAssetEntity modelAsset = requireOrIngest(
                FileAssetKind.TTS_MODEL,
                selector.modelCode() + "/model-" + descriptor.modelSha256() + ".onnx",
                "application/octet-stream",
                descriptor,
                modelBytes,
                descriptor.modelSha256());
        FileAssetEntity configAsset = requireOrIngest(
                FileAssetKind.TTS_CONFIG,
                selector.modelCode() + "/config-" + descriptor.configSha256() + ".json",
                "application/json",
                descriptor,
                configBytes,
                descriptor.configSha256());

        return modelRepository.saveAndFlush(new TtsVoiceModelEntity(
                selector.modelCode(),
                voice,
                TtsEngine.PIPER,
                descriptor.engineVersion(),
                descriptor.modelVersion(),
                modelAsset.getId(),
                configAsset.getId(),
                descriptor.modelSha256(),
                descriptor.configSha256(),
                descriptor.sourceProvider(),
                descriptor.sourceRepository(),
                descriptor.sourceRevision(),
                TtsVoiceModelStatus.READY_FOR_REVIEW,
                descriptor.licenseName(),
                descriptor.licenseReference(),
                false,
                null));
    }

    private static TtsModelArtifactSource.ArtifactRequest request(
            TtsModelCatalogGateway.ModelDescriptor descriptor,
            String url) {
        return new TtsModelArtifactSource.ArtifactRequest(
                descriptor.sourceProvider(),
                descriptor.sourceRepository(),
                descriptor.sourceRevision(),
                url);
    }

    private FileAssetEntity requireOrIngest(
            FileAssetKind kind,
            String relativeKey,
            String mediaType,
            TtsModelCatalogGateway.ModelDescriptor descriptor,
            byte[] bytes,
            String expectedSha) {
        String bucket = objectStorage.defaultBucket();
        String objectKey = "tts/models/" + relativeKey;
        var existing = assetRepository.findByBucketAndObjectKey(bucket, objectKey);
        if (existing.isPresent()) {
            FileAssetEntity asset = existing.orElseThrow();
            if (asset.getKind() != kind
                    || asset.getStatus() != FileAssetStatus.READY
                    || !asset.getSha256().equals(expectedSha)) {
                throw new IllegalStateException("Existing TTS asset conflicts with immutable provisioning identity");
            }
            return asset;
        }

        return ingestService.ingest(new FileAssetIngestService.IngestCommand(
                kind,
                bucket,
                objectKey,
                mediaType,
                Map.of(
                        "source-provider", descriptor.sourceProvider(),
                        "source-repository", descriptor.sourceRepository(),
                        "source-revision", descriptor.sourceRevision()),
                bytes));
    }

    private static void verifySha(byte[] bytes, String expectedSha, String label) {
        String actual = sha256(bytes);
        if (!actual.equals(expectedSha)) {
            throw new TtsModelIntegrityException(label + " SHA-256 mismatch");
        }
    }

    private static String sha256(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    public static class TtsModelIntegrityException extends RuntimeException {
        public TtsModelIntegrityException(String message) {
            super(message);
        }
    }
}
