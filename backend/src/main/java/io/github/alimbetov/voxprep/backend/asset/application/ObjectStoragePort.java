package io.github.alimbetov.voxprep.backend.asset.application;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.util.Map;

/** Application-facing object storage boundary shared by media-producing domains. */
public interface ObjectStoragePort {

    /** Default internal bucket for backend-managed assets. */
    String defaultBucket();

    byte[] read(String bucket, String objectKey);

    /** Streaming read for verification; production adapters must override to avoid full buffering. */
    default InputStream openRead(String bucket, String objectKey) {
        return new ByteArrayInputStream(read(bucket, objectKey));
    }

    void write(
            String bucket,
            String objectKey,
            String mediaType,
            Map<String, String> metadata,
            byte[] bytes);
}
