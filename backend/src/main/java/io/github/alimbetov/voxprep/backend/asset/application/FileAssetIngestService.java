package io.github.alimbetov.voxprep.backend.asset.application;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.domain.MediaAssetPolicy;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.HexFormat;
import java.util.Map;
import java.util.Objects;
import org.springframework.stereotype.Service;

/**
 * Shared ingest lifecycle for assets written by the backend.
 *
 * <p>Database transitions are deliberately committed around the object-store call:
 * REGISTERED is durable before upload begins, while FAILED/QUARANTINED remain durable
 * when storage or integrity verification fails.
 */
@Service
public class FileAssetIngestService {

    private static final String SHA256_METADATA = "sha256";
    private static final String SIZE_METADATA = "size-bytes";

    private final FileAssetRepository assetRepository;
    private final ObjectStoragePort objectStorage;

    public FileAssetIngestService(FileAssetRepository assetRepository, ObjectStoragePort objectStorage) {
        this.assetRepository = Objects.requireNonNull(assetRepository, "assetRepository");
        this.objectStorage = Objects.requireNonNull(objectStorage, "objectStorage");
    }

    public FileAssetEntity ingest(IngestCommand command) {
        Objects.requireNonNull(command, "command");
        byte[] bytes = Objects.requireNonNull(command.bytes(), "bytes");
        if (bytes.length == 0) {
            throw new IllegalArgumentException("FileAsset payload must not be empty");
        }
        MediaAssetPolicy.validate(command.kind(), command.mediaType(), bytes.length);

        String sha256 = sha256(bytes);
        FileAssetEntity asset = assetRepository.saveAndFlush(new FileAssetEntity(
                command.kind(),
                FileAssetStatus.REGISTERED,
                command.bucket(),
                command.objectKey(),
                command.mediaType(),
                bytes.length,
                sha256));

        byte[] stored;
        try {
            objectStorage.write(
                    asset.getBucket(),
                    asset.getObjectKey(),
                    asset.getMediaType(),
                    integrityMetadata(command.metadata(), sha256, bytes.length),
                    bytes);
            stored = objectStorage.read(asset.getBucket(), asset.getObjectKey());
        } catch (RuntimeException exception) {
            asset.markFailed();
            assetRepository.saveAndFlush(asset);
            throw new AssetStorageException("Object storage write/read failed for " + asset.getObjectKey(), exception);
        }

        if (stored.length != asset.getSizeBytes() || !sha256(stored).equals(asset.getSha256())) {
            asset.markQuarantined();
            assetRepository.saveAndFlush(asset);
            throw new AssetIntegrityException("Stored object does not match FileAsset checksum/size invariants");
        }

        asset.markReady();
        return assetRepository.saveAndFlush(asset);
    }

    private static Map<String, String> integrityMetadata(
            Map<String, String> metadata,
            String sha256,
            long sizeBytes) {
        Map<String, String> effective = new HashMap<>();
        if (metadata != null) {
            effective.putAll(metadata);
        }
        effective.put(SHA256_METADATA, sha256);
        effective.put(SIZE_METADATA, Long.toString(sizeBytes));
        return Map.copyOf(effective);
    }

    private static String sha256(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    public record IngestCommand(
            FileAssetKind kind,
            String bucket,
            String objectKey,
            String mediaType,
            Map<String, String> metadata,
            byte[] bytes) {

        public IngestCommand {
            Objects.requireNonNull(kind, "kind");
            bucket = required(bucket, "bucket");
            objectKey = required(objectKey, "objectKey");
            mediaType = required(mediaType, "mediaType");
            bytes = Objects.requireNonNull(bytes, "bytes").clone();
            metadata = metadata == null ? Map.of() : Map.copyOf(metadata);
        }

        @Override
        public byte[] bytes() {
            return bytes.clone();
        }

        private static String required(String value, String field) {
            Objects.requireNonNull(value, field);
            String normalized = value.strip();
            if (normalized.isEmpty() || !normalized.equals(value)) {
                throw new IllegalArgumentException("Invalid " + field);
            }
            return value;
        }
    }

    public static class AssetStorageException extends RuntimeException {
        public AssetStorageException(String message, Throwable cause) {
            super(message, cause);
        }
    }

    public static class AssetIntegrityException extends RuntimeException {
        public AssetIntegrityException(String message) {
            super(message);
        }
    }
}
