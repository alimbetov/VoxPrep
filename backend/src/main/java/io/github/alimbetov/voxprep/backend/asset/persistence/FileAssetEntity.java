package io.github.alimbetov.voxprep.backend.asset.persistence;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.infrastructure.persistence.AbstractJpaEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.util.Objects;

@Entity
@Table(
        name = "file_asset",
        schema = "app",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_file_asset__storage",
                columnNames = {"bucket", "object_key"}))
public class FileAssetEntity extends AbstractJpaEntity {

    @Enumerated(EnumType.STRING)
    @Column(name = "kind", nullable = false, updatable = false, length = 32)
    private FileAssetKind kind;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 32)
    private FileAssetStatus status;

    @Column(name = "bucket", nullable = false, updatable = false, length = 128)
    private String bucket;

    @Column(name = "object_key", nullable = false, updatable = false, length = 1024)
    private String objectKey;

    @Column(name = "media_type", nullable = false, updatable = false, length = 128)
    private String mediaType;

    @Column(name = "size_bytes", nullable = false)
    private long sizeBytes;

    @Column(name = "sha256", nullable = false, updatable = false, length = 64)
    private String sha256;

    protected FileAssetEntity() {
    }

    public FileAssetEntity(
            FileAssetKind kind,
            FileAssetStatus status,
            String bucket,
            String objectKey,
            String mediaType,
            long sizeBytes,
            String sha256) {
        this.kind = Objects.requireNonNull(kind, "kind");
        this.status = Objects.requireNonNull(status, "status");
        this.bucket = required(bucket, "bucket", 128);
        this.objectKey = required(objectKey, "objectKey", 1024);
        this.mediaType = required(mediaType, "mediaType", 128);
        if (sizeBytes < 0) {
            throw new IllegalArgumentException("sizeBytes must be non-negative");
        }
        this.sizeBytes = sizeBytes;
        this.sha256 = sha256(sha256);
    }

    public void updateStatus(FileAssetStatus status) {
        this.status = Objects.requireNonNull(status, "status");
    }

    public FileAssetKind getKind() {
        return kind;
    }

    public FileAssetStatus getStatus() {
        return status;
    }

    public String getBucket() {
        return bucket;
    }

    public String getObjectKey() {
        return objectKey;
    }

    public String getMediaType() {
        return mediaType;
    }

    public long getSizeBytes() {
        return sizeBytes;
    }

    public String getSha256() {
        return sha256;
    }

    private static String required(String value, String field, int maxLength) {
        Objects.requireNonNull(value, field);
        String normalized = value.strip();
        if (normalized.isEmpty()) {
            throw new IllegalArgumentException(field + " must not be blank");
        }
        if (!normalized.equals(value)) {
            throw new IllegalArgumentException(field + " must not contain surrounding whitespace");
        }
        if (value.length() > maxLength) {
            throw new IllegalArgumentException(field + " exceeds max length " + maxLength);
        }
        return value;
    }

    private static String sha256(String value) {
        Objects.requireNonNull(value, "sha256");
        if (!value.matches("[0-9a-f]{64}")) {
            throw new IllegalArgumentException("sha256 must be lowercase SHA-256");
        }
        return value;
    }
}
