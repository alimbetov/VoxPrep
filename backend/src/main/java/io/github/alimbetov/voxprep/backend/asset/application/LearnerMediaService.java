package io.github.alimbetov.voxprep.backend.asset.application;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class LearnerMediaService {

    private static final Set<FileAssetKind> LEARNER_KINDS = Set.of(
            FileAssetKind.TTS_AUDIO,
            FileAssetKind.COVER_IMAGE,
            FileAssetKind.CONTENT_IMAGE);

    private final FileAssetRepository assetRepository;
    private final ObjectStoragePort objectStorage;

    public LearnerMediaService(FileAssetRepository assetRepository, ObjectStoragePort objectStorage) {
        this.assetRepository = Objects.requireNonNull(assetRepository, "assetRepository");
        this.objectStorage = Objects.requireNonNull(objectStorage, "objectStorage");
    }

    @Transactional(readOnly = true)
    public MediaDescriptor describe(UUID assetId) {
        FileAssetEntity asset = requireDeliverable(assetId);
        return new MediaDescriptor(
                asset.getId(),
                asset.getBucket(),
                asset.getObjectKey(),
                asset.getMediaType(),
                asset.getSizeBytes(),
                asset.getSha256(),
                '"' + asset.getSha256() + '"');
    }

    public MediaContent read(MediaDescriptor descriptor) {
        Objects.requireNonNull(descriptor, "descriptor");
        byte[] bytes = objectStorage.read(descriptor.bucket(), descriptor.objectKey());
        if (bytes.length != descriptor.sizeBytes() || !sha256(bytes).equals(descriptor.sha256())) {
            quarantine(descriptor.assetId());
            throw new MediaIntegrityException("Media asset failed checksum/size verification");
        }
        return new MediaContent(descriptor.mediaType(), bytes);
    }

    private FileAssetEntity requireDeliverable(UUID assetId) {
        FileAssetEntity asset = assetRepository.findById(Objects.requireNonNull(assetId, "assetId"))
                .orElseThrow(() -> new MediaUnavailableException("Media asset not found"));
        if (!LEARNER_KINDS.contains(asset.getKind()) || asset.getStatus() != FileAssetStatus.READY) {
            throw new MediaUnavailableException("Media asset is not deliverable");
        }
        return asset;
    }

    @Transactional
    void quarantine(UUID assetId) {
        FileAssetEntity asset = assetRepository.findById(assetId)
                .orElseThrow(() -> new MediaUnavailableException("Media asset not found"));
        if (asset.getStatus() == FileAssetStatus.READY) {
            asset.markQuarantined();
            assetRepository.saveAndFlush(asset);
        }
    }

    private static String sha256(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    public record MediaDescriptor(
            UUID assetId,
            String bucket,
            String objectKey,
            String mediaType,
            long sizeBytes,
            String sha256,
            String etag) {
    }

    public record MediaContent(String mediaType, byte[] bytes) {
        public MediaContent {
            mediaType = Objects.requireNonNull(mediaType, "mediaType");
            bytes = Objects.requireNonNull(bytes, "bytes").clone();
        }

        @Override
        public byte[] bytes() {
            return bytes.clone();
        }
    }

    public static class MediaUnavailableException extends RuntimeException {
        public MediaUnavailableException(String message) {
            super(message);
        }
    }

    public static class MediaIntegrityException extends RuntimeException {
        public MediaIntegrityException(String message) {
            super(message);
        }
    }
}
