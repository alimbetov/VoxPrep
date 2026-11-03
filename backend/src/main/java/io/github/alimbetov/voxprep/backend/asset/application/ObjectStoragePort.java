package io.github.alimbetov.voxprep.backend.asset.application;

import java.util.Map;

/**
 * Application-facing object storage boundary shared by media-producing domains.
 *
 * <p>The port deliberately exposes bucket/object identity because {@code FileAsset}
 * persists that identity and remains the source of truth for stored artifacts.
 */
public interface ObjectStoragePort {

    byte[] read(String bucket, String objectKey);

    void write(
            String bucket,
            String objectKey,
            String mediaType,
            Map<String, String> metadata,
            byte[] bytes);
}
