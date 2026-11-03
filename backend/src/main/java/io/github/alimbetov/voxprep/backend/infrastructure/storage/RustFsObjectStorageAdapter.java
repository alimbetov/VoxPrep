package io.github.alimbetov.voxprep.backend.infrastructure.storage;

import io.github.alimbetov.voxprep.backend.asset.application.ObjectStoragePort;
import java.io.InputStream;
import java.util.Map;
import java.util.Objects;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.core.ResponseBytes;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

@Component
public class RustFsObjectStorageAdapter implements ObjectStoragePort {

    private final S3Client s3Client;
    private final RustFsProperties properties;

    public RustFsObjectStorageAdapter(S3Client s3Client, RustFsProperties properties) {
        this.s3Client = Objects.requireNonNull(s3Client, "s3Client");
        this.properties = Objects.requireNonNull(properties, "properties");
    }

    @Override
    public String defaultBucket() {
        return required(properties.getBucket(), "bucket");
    }

    @Override
    public byte[] read(String bucket, String objectKey) {
        ResponseBytes<GetObjectResponse> object = s3Client.getObjectAsBytes(GetObjectRequest.builder()
                .bucket(required(bucket, "bucket"))
                .key(required(objectKey, "objectKey"))
                .build());
        return object.asByteArray();
    }

    @Override
    public InputStream openRead(String bucket, String objectKey) {
        return s3Client.getObject(GetObjectRequest.builder()
                .bucket(required(bucket, "bucket"))
                .key(required(objectKey, "objectKey"))
                .build());
    }

    @Override
    public void write(
            String bucket,
            String objectKey,
            String mediaType,
            Map<String, String> metadata,
            byte[] bytes) {
        Objects.requireNonNull(bytes, "bytes");
        Map<String, String> safeMetadata = metadata == null ? Map.of() : Map.copyOf(metadata);
        s3Client.putObject(
                PutObjectRequest.builder()
                        .bucket(required(bucket, "bucket"))
                        .key(required(objectKey, "objectKey"))
                        .contentType(required(mediaType, "mediaType"))
                        .metadata(safeMetadata)
                        .build(),
                RequestBody.fromBytes(bytes));
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
