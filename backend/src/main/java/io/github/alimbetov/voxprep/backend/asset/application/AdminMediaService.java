package io.github.alimbetov.voxprep.backend.asset.application;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.domain.ImageMediaTypeDetector;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Objects;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminMediaService {

    private final FileAssetIngestService ingestService;
    private final FileAssetRepository assetRepository;
    private final ObjectStoragePort objectStorage;

    public AdminMediaService(
            FileAssetIngestService ingestService,
            FileAssetRepository assetRepository,
            ObjectStoragePort objectStorage) {
        this.ingestService = Objects.requireNonNull(ingestService, "ingestService");
        this.assetRepository = Objects.requireNonNull(assetRepository, "assetRepository");
        this.objectStorage = Objects.requireNonNull(objectStorage, "objectStorage");
    }

    public AssetView upload(FileAssetKind kind, byte[] bytes) {
        requireImageKind(kind);
        byte[] safeBytes = Objects.requireNonNull(bytes, "bytes").clone();
        ImageMediaTypeDetector.DetectedImage detected = ImageMediaTypeDetector.detect(safeBytes);
        String objectKey = objectKey(kind, detected.extension());

        FileAssetEntity asset = ingestService.ingest(new FileAssetIngestService.IngestCommand(
                kind,
                objectStorage.defaultBucket(),
                objectKey,
                detected.mediaType(),
                Map.of("asset-kind", kind.name()),
                safeBytes));
        return view(asset);
    }

    @Transactional(readOnly = true)
    public AssetContent preview(UUID assetId) {
        FileAssetEntity asset = assetRepository.findById(Objects.requireNonNull(assetId, "assetId"))
                .orElseThrow(() -> new NoSuchElementException("Media asset not found"));
        requireImageKind(asset.getKind());
        if (asset.getStatus() != FileAssetStatus.READY) {
            throw new NoSuchElementException("Media asset is not ready");
        }
        byte[] bytes = objectStorage.read(asset.getBucket(), asset.getObjectKey());
        return new AssetContent(asset.getMediaType(), bytes);
    }

    private static AssetView view(FileAssetEntity asset) {
        return new AssetView(
                asset.getId(),
                asset.getKind(),
                asset.getStatus(),
                asset.getMediaType(),
                asset.getSizeBytes(),
                asset.getSha256());
    }

    private static void requireImageKind(FileAssetKind kind) {
        Objects.requireNonNull(kind, "kind");
        if (kind != FileAssetKind.COVER_IMAGE && kind != FileAssetKind.CONTENT_IMAGE) {
            throw new IllegalArgumentException("ADMIN media upload supports only COVER_IMAGE or CONTENT_IMAGE");
        }
    }

    private static String objectKey(FileAssetKind kind, String extension) {
        String namespace = kind == FileAssetKind.COVER_IMAGE ? "cover" : "content";
        return "media/" + namespace + "/" + UUID.randomUUID() + "." + extension;
    }

    public record AssetView(
            UUID assetId,
            FileAssetKind kind,
            FileAssetStatus status,
            String mediaType,
            long sizeBytes,
            String sha256) {
    }

    public record AssetContent(String mediaType, byte[] bytes) {
        public AssetContent {
            mediaType = Objects.requireNonNull(mediaType, "mediaType");
            bytes = Objects.requireNonNull(bytes, "bytes").clone();
        }

        @Override
        public byte[] bytes() {
            return bytes.clone();
        }
    }
}
