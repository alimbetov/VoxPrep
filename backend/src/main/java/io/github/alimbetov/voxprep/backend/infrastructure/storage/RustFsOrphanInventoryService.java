package io.github.alimbetov.voxprep.backend.infrastructure.storage;

import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import java.util.List;
import java.util.Objects;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.ListObjectsV2Request;

/**
 * Read-only snapshot of potentially untracked RustFS keys. Never deletes objects.
 *
 * <p>A missing database row is not proof that an object is safe to delete: concurrent
 * ingests and eventual store visibility require a separate age-graced confirmation.
 */
@Service
public class RustFsOrphanInventoryService {

    private static final int MAX_PAGE_SIZE = 100;

    private final S3Client s3;
    private final FileAssetRepository assets;
    private final RustFsProperties properties;

    public RustFsOrphanInventoryService(
            S3Client s3, FileAssetRepository assets, RustFsProperties properties) {
        this.s3 = Objects.requireNonNull(s3, "s3");
        this.assets = Objects.requireNonNull(assets, "assets");
        this.properties = Objects.requireNonNull(properties, "properties");
    }

    public InventoryPage scan(String prefix, String continuationToken, int pageSize) {
        if (prefix == null || prefix.isBlank() || prefix.startsWith("/") || prefix.contains("..")) {
            throw new IllegalArgumentException("A restricted nonblank object prefix is required");
        }
        if (pageSize < 1 || pageSize > MAX_PAGE_SIZE) {
            throw new IllegalArgumentException("pageSize must be between 1 and " + MAX_PAGE_SIZE);
        }
        String bucket = properties.getBucket();
        var request = ListObjectsV2Request.builder()
                .bucket(bucket)
                .prefix(prefix)
                .continuationToken(continuationToken == null || continuationToken.isBlank()
                        ? null : continuationToken)
                .maxKeys(pageSize)
                .build();
        var result = s3.listObjectsV2(request);
        List<InventoryEntry> entries = result.contents().stream()
                .map(object -> new InventoryEntry(
                        object.key(),
                        object.size(),
                        object.lastModified(),
                        assets.findByBucketAndObjectKey(bucket, object.key()).isEmpty()))
                .toList();
        return new InventoryPage(entries, result.nextContinuationToken(), Boolean.TRUE.equals(result.isTruncated()));
    }

    /** suspectedOrphan is strictly advisory: no deletion authorization is implied. */
    public record InventoryEntry(
            String key, Long sizeBytes, java.time.Instant lastModified, boolean suspectedOrphan) {
    }

    public record InventoryPage(
            List<InventoryEntry> entries, String nextContinuationToken, boolean truncated) {
        public InventoryPage {
            entries = List.copyOf(entries);
        }
    }
}
