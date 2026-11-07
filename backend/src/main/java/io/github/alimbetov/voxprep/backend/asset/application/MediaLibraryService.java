package io.github.alimbetov.voxprep.backend.asset.application;

import io.github.alimbetov.voxprep.backend.asset.domain.ContentAssetRole;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.domain.MediaAssetPolicy;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Admin-only use cases. Reuse is by compatible image kind + MIME + size + SHA-256,
 * not by filename, and only READY assets are selectable.
 */
@Service
public class MediaLibraryService {
    private final FileAssetRepository files;
    private final FileAssetIngestService ingest;
    private final ContentAssetBindingService bindings;
    private final ObjectStoragePort storage;
    private final JdbcTemplate jdbc;
    private final TransactionTemplate tx;
    private final String bucket;

    public MediaLibraryService(FileAssetRepository files, FileAssetIngestService ingest,
            ContentAssetBindingService bindings, ObjectStoragePort storage,
            JdbcTemplate jdbc, org.springframework.transaction.PlatformTransactionManager manager,
            @Value("${voxprep.storage.bucket}") String bucket) {
        this.files = files;
        this.ingest = ingest;
        this.bindings = bindings;
        this.storage = storage;
        this.jdbc = jdbc;
        this.tx = new TransactionTemplate(manager);
        this.bucket = bucket;
    }

    public List<FileAssetEntity> list(ContentAssetRole role, int page) {
        requireImageRole(role);
        if (page < 0 || page > 10000) throw new IllegalArgumentException("Invalid page");
        return files.findByKindInAndStatusOrderByCreatedAtDesc(
                List.of(role.assetKind()), FileAssetStatus.READY, PageRequest.of(page, 24));
    }

    public List<BoundImage> boundImages(UUID revisionId) {
        return jdbc.query("""
                SELECT b.role, f.id, f.status
                FROM app.content_asset_binding b JOIN app.file_asset f ON f.id = b.file_asset_id
                WHERE b.content_revision_id = ? AND b.role IN ('COVER_IMAGE', 'CONTENT_IMAGE')
                ORDER BY b.role
                """, (row, index) -> new BoundImage(row.getString("role"),
                        row.getObject("id", UUID.class), "READY".equals(row.getString("status"))), revisionId);
    }

    public record BoundImage(String role, UUID assetId, boolean ready) {
        public String label() { return "COVER_IMAGE".equals(role) ? "Cover image" : "Content image"; }
    }

    public FileAssetEntity requireReadyImage(UUID id) {
        FileAssetEntity file = files.findById(Objects.requireNonNull(id))
                .orElseThrow(() -> new IllegalArgumentException("Image not found"));
        if (file.getStatus() != FileAssetStatus.READY
                || !imageKind(file.getKind())) {
            throw new IllegalArgumentException("Image is unavailable");
        }
        return file;
    }

    public byte[] preview(UUID assetId) {
        FileAssetEntity file = requireReadyImage(assetId);
        byte[] bytes = storage.read(file.getBucket(), file.getObjectKey());
        if (bytes.length != file.getSizeBytes() || !sha(bytes).equals(file.getSha256())) {
            throw new IllegalStateException("Stored image fails integrity verification");
        }
        return bytes;
    }

    public FileAssetEntity upload(ContentAssetRole role, String mediaType, byte[] bytes) {
        requireImageRole(role);
        Objects.requireNonNull(bytes, "bytes");
        MediaAssetPolicy.validate(role.assetKind(), mediaType, bytes.length);
        validateMagic(mediaType, bytes);
        String digest = sha(bytes);
        // PostgreSQL transaction-scoped advisory lock across backend replicas.
        // The lock serializes "find READY → upload" for this exact content fingerprint.
        // Database failure rolls back its records; H2 handles storage orphan reconciliation.
        return Objects.requireNonNull(tx.execute(status -> {
            jdbc.execute((org.springframework.jdbc.core.ConnectionCallback<Void>) connection -> {
                try (var statement = connection.prepareStatement(
                        "select pg_advisory_xact_lock(hashtextextended(?::text,0))")) {
                    statement.setString(1, role.assetKind().name() + ":" + mediaType + ":" + digest);
                    statement.execute();
                }
                return null;
            });
            var existing = files.findFirstByKindAndMediaTypeAndSha256AndSizeBytesAndStatus(
                    role.assetKind(), mediaType, digest, bytes.length, FileAssetStatus.READY);
            if (existing.isPresent()) return existing.orElseThrow();
            String key = "media-library/" + role.assetKind().name().toLowerCase()
                    + "/" + UUID.randomUUID();
            return ingest.ingest(new FileAssetIngestService.IngestCommand(
                    role.assetKind(), bucket, key, mediaType, Map.of(), bytes));
        }));
    }

    public void bind(UUID revisionId, ContentAssetRole role, UUID assetId) {
        requireImageRole(role);
        // Reuse existing row lock and immutable-published-revision enforcement.
        bindings.bind(revisionId, role, assetId, null);
    }

    private static void requireImageRole(ContentAssetRole role) {
        if (role == null || role.audio() || !imageKind(role.assetKind())) {
            throw new IllegalArgumentException("Only image binding roles are supported");
        }
    }

    private static boolean imageKind(FileAssetKind kind) {
        return kind == FileAssetKind.COVER_IMAGE || kind == FileAssetKind.CONTENT_IMAGE;
    }

    private static void validateMagic(String type, byte[] b) {
        boolean png = b.length >= 24 && (b[0] & 255) == 137 && b[1] == 80
                && b[2] == 78 && b[3] == 71 && b[4] == 13
                && b[5] == 10 && b[6] == 26 && b[7] == 10;
        boolean jpg = b.length >= 4 && (b[0] & 255) == 255
                && (b[1] & 255) == 216 && (b[2] & 255) == 255;
        boolean webp = b.length >= 12 && b[0] == 'R' && b[1] == 'I'
                && b[2] == 'F' && b[3] == 'F'
                && b[8] == 'W' && b[9] == 'E' && b[10] == 'B' && b[11] == 'P';
        if (!(("image/png".equals(type) && png)
                || ("image/jpeg".equals(type) && jpg)
                || ("image/webp".equals(type) && webp))) {
            throw new IllegalArgumentException("Image signature does not match media type");
        }
    }

    private static String sha(byte[] b) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(b));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 unavailable", e);
        }
    }
}
