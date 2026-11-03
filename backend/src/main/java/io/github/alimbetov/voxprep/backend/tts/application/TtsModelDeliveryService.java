package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelRepository;
import java.util.NoSuchElementException;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import software.amazon.awssdk.core.ResponseBytes;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;

@Service
public class TtsModelDeliveryService {

    public enum ArtifactType { MODEL, CONFIG }

    public record Artifact(byte[] bytes, String mediaType, String sha256) { }

    private final TtsVoiceModelRepository modelRepository;
    private final FileAssetRepository assetRepository;
    private final S3Client s3Client;

    public TtsModelDeliveryService(
            TtsVoiceModelRepository modelRepository,
            FileAssetRepository assetRepository,
            S3Client s3Client) {
        this.modelRepository = modelRepository;
        this.assetRepository = assetRepository;
        this.s3Client = s3Client;
    }

    @Transactional(readOnly = true)
    public Artifact download(UUID voiceModelId, ArtifactType type) {
        var model = modelRepository.findById(voiceModelId)
                .orElseThrow(() -> new NoSuchElementException("TTS voice model not found"));
        if (model.getStatus() == io.github.alimbetov.voxprep.backend.tts.domain.TtsVoiceModelStatus.INVALID
                || model.getStatus() == io.github.alimbetov.voxprep.backend.tts.domain.TtsVoiceModelStatus.QUARANTINED) {
            throw new NoSuchElementException("TTS voice model is not deliverable");
        }
        UUID assetId = type == ArtifactType.MODEL ? model.getModelAssetId() : model.getConfigAssetId();
        FileAssetKind kind = type == ArtifactType.MODEL ? FileAssetKind.TTS_MODEL : FileAssetKind.TTS_CONFIG;
        String expectedHash = type == ArtifactType.MODEL ? model.getModelSha256() : model.getConfigSha256();
        var asset = requireAsset(assetId, kind, expectedHash);
        ResponseBytes<GetObjectResponse> object = s3Client.getObjectAsBytes(GetObjectRequest.builder()
                .bucket(asset.getBucket()).key(asset.getObjectKey()).build());
        return new Artifact(object.asByteArray(), asset.getMediaType(), asset.getSha256());
    }

    private FileAssetEntity requireAsset(UUID id, FileAssetKind kind, String expectedHash) {
        var asset = assetRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("TTS model asset is missing"));
        if (asset.getKind() != kind || asset.getStatus() != FileAssetStatus.READY || !asset.getSha256().equals(expectedHash)) {
            throw new NoSuchElementException("TTS model asset is unavailable");
        }
        return asset;
    }
}
