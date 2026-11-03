package io.github.alimbetov.voxprep.backend.asset.application;

import java.util.Map;

/** Application-facing object storage boundary shared by media-producing domains. */
public interface ObjectStoragePort {

    /** Default internal bucket for backend-managed assets. */
    String defaultBucket();

    byte[] read(String bucket, String objectKey);

    void write(
            String bucket,
            String objectKey,
            String mediaType,
            Map<String, String> metadata,
            byte[] bytes);
}
