package io.github.alimbetov.voxprep.backend.infrastructure.storage;

import org.springframework.boot.actuate.health.AbstractHealthIndicator;
import org.springframework.boot.actuate.health.Health;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.HeadBucketRequest;

@Component("rustFs")
public class RustFsHealthIndicator extends AbstractHealthIndicator {

    private final S3Client s3Client;
    private final RustFsProperties properties;

    public RustFsHealthIndicator(S3Client s3Client, RustFsProperties properties) {
        this.s3Client = s3Client;
        this.properties = properties;
    }

    @Override
    protected void doHealthCheck(Health.Builder builder) {
        try {
            s3Client.headBucket(HeadBucketRequest.builder()
                    .bucket(properties.getBucket())
                    .build());
            builder.up();
        } catch (Exception ex) {
            builder.down(ex);
        }
    }
}
