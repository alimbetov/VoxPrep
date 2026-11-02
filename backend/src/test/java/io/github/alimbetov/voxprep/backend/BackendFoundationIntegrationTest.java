package io.github.alimbetov.voxprep.backend;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.infrastructure.storage.RustFsProperties;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

@ActiveProfiles("test")
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class BackendFoundationIntegrationTest {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private S3Client s3Client;

    @Autowired
    private RustFsProperties storageProperties;

    @LocalServerPort
    private int serverPort;

    @Test
    void runtimeDatasourceUsesLeastPrivilegeRole() {
        String currentUser = jdbcTemplate.queryForObject("select current_user", String.class);

        assertThat(currentUser).isEqualTo("voxprep_backend");
        assertThatThrownBy(() -> jdbcTemplate.execute(
                        "create table app.runtime_must_not_create(id bigint primary key)"))
                .isInstanceOf(DataAccessException.class);
    }

    @Test
    void runtimeDatasourceCanUseMigratedApplicationTables() {
        String id = UUID.randomUUID().toString();
        String payload = "backend-foundation";

        jdbcTemplate.update(
                "insert into app.foundation_runtime_probe(id, payload) values (?, ?)", id, payload);

        String persisted = jdbcTemplate.queryForObject(
                "select payload from app.foundation_runtime_probe where id = ?",
                String.class,
                id);

        assertThat(persisted).isEqualTo(payload);
        jdbcTemplate.update("delete from app.foundation_runtime_probe where id = ?", id);
    }

    @Test
    void runtimeDatasourceCannotReadLiquibaseMetadata() {
        assertThatThrownBy(() -> jdbcTemplate.queryForObject(
                        "select count(*) from liquibase.databasechangelog", Long.class))
                .isInstanceOf(DataAccessException.class);
    }

    @Test
    void backendCredentialCanRoundTripRustFsObject() {
        String key = "staging/qualification/" + UUID.randomUUID() + ".txt";
        String payload = "voxprep-backend-foundation";

        try {
            s3Client.putObject(
                    PutObjectRequest.builder()
                            .bucket(storageProperties.getBucket())
                            .key(key)
                            .contentType("text/plain")
                            .build(),
                    RequestBody.fromBytes(payload.getBytes(StandardCharsets.UTF_8)));

            var response = s3Client.getObjectAsBytes(GetObjectRequest.builder()
                    .bucket(storageProperties.getBucket())
                    .key(key)
                    .build());

            assertThat(response.asUtf8String()).isEqualTo(payload);
        } finally {
            s3Client.deleteObject(DeleteObjectRequest.builder()
                    .bucket(storageProperties.getBucket())
                    .key(key)
                    .build());
        }
    }

    @Test
    void readinessIsUpWhenDatabaseAndRustFsAreReachable() throws Exception {
        var client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(2))
                .build();
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://127.0.0.1:" + serverPort + "/actuator/health/readiness"))
                .timeout(Duration.ofSeconds(5))
                .GET()
                .build();

        var response = client.send(request, HttpResponse.BodyHandlers.ofString());

        assertThat(response.statusCode()).isEqualTo(200);
        assertThat(response.body()).contains("\"status\":\"UP\"");
    }
}
