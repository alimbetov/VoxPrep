package io.github.alimbetov.voxprep.backend.infrastructure.storage;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.http.apache5.Apache5HttpClient;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;

@Configuration(proxyBeanMethods = false)
public class RustFsConfiguration {

    @Bean(destroyMethod = "close")
    S3Client rustFsS3Client(RustFsProperties properties) {
        var s3Configuration = S3Configuration.builder()
                .pathStyleAccessEnabled(true)
                .build();

        return S3Client.builder()
                .endpointOverride(properties.getEndpoint())
                .region(Region.of(properties.getRegion()))
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create(properties.getAccessKey(), properties.getSecretKey())))
                .serviceConfiguration(s3Configuration)
                .httpClientBuilder(Apache5HttpClient.builder()
                        .connectionTimeout(properties.getConnectTimeout())
                        .socketTimeout(properties.getSocketTimeout())
                        .maxConnections(properties.getMaxConnections()))
                .build();
    }
}
