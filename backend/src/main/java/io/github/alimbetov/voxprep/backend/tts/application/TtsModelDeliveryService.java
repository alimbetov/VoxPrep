package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelRepository;
import java.net.URI;
import java.util.NoSuchElementException;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;

@Service
public class TtsModelDeliveryService {

    private final TtsVoiceModelRepository modelRepository;
    private final FileAssetRepository assetRepository;
    private final S3Presigner presigner;
    private final WorkerDeliveryProperties properties;

    public TtsModelDeliveryService(
            TtsVoiceModelRepository modelRepository,
            FileAssetRepository assetRepository,
            S3Presigner presigner,
            WorkerDeliveryProperties properties) {
        this.modelRepository = modelRepository;
        this.assetRepository = assetRepository;
        this.presigner = presigner;
        this.properties = properties;
    }

    @Transactional(readOnly = true)
    public TtsModelDelivery delivery(UUID voiceModelId) {
        var model = modelRepository.findById(voiceModelId)
                .orElseThrow(() -> new NoSuchElementException("TTS voice model not found"));
        if (!model.selectableForNewJobs()) {
            throw new IllegalStateException("TTS voice model is not active for new jobs");
        }

        var modelAsset = requireAsset(model.getModelAssetId(), FileAssetKind.TTS_MODEL, model.getModelSha256());
        var configAsset = requireAsset(model.getConfigAssetId(), FileAssetKind.TTS_CONFIG, model.getConfigSha256());

        return new TtsModelDelivery(
                model.getId(),
                model.getEngine(),
                model.getEngineVersion(),
                model.getModelVersion(),
                artifact(modelAsset),
                artifact(configAsset));
    }

    private FileAssetEntity requireAsset(UUID id, FileAssetKind kind, String expectedHash) {
        var asset = assetRepository.findById(id)
                .orElseThrow(() -> new IllegalStateException("TTS model asset is missing"));
        if (asset.getKind() != kind || asset.getStatus() != FileAssetStatus.READY) {
            throw new IllegalStateException("TTS model asset is not READY with expected kind");
        }
        if (!asset.getSha256().equals(expectedHash)) {
            throw new IllegalStateException("TTS model asset checksum does not match catalogue identity");
        }
        return asset;
    }

    private TtsModelDelivery.Artifact artifact(FileAssetEntity asset) {
        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(asset.getBucket())
                .key(asset.getObjectKey())
                .build();
        GetObjectPresignRequest request = GetObjectPresignRequest.builder()
                .signatureDuration(properties.getUrlTtl())
                .getObjectRequest(getObjectRequest)
                .build();
        URI uri = URI.create(presigner.presignGetObject(request).url().toString());
        return new TtsModelDelivery.Artifact(
                asset.getId(),
                uri,
                asset.getSha256(),
                asset.getSizeBytes(),
                asset.getMediaType());
    }
}
