package io.github.alimbetov.voxprep.backend.content.dev;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.core.io.ClassPathResource;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import tools.jackson.databind.ObjectMapper;

/**
 * Runs the real DEV opt-in ApplicationRunner against the PostgreSQL supplied
 * by B1, then replays it without replacing any first revision.
 */
@SpringBootTest
@ActiveProfiles({"test", "dev"})
@TestPropertySource(properties = "voxprep.dev.demo-seed-enabled=true")
class DemoCatalogueSeedPostgresIntegrationTest {
    @Autowired private DemoCatalogueSeedRunner runner;
    @Autowired private ContentRevisionRepository revisions;
    @Autowired private ObjectMapper json;

    @Test
    void devBootCreatesRealDraftRevisionsAndReplayKeepsIdentities() throws Exception {
        var fixture = new ClassPathResource("dev-fixtures/demo_catalogue_seed.json");
        Map<?, ?> document;
        try (var stream = fixture.getInputStream()) {
            document = json.readValue(stream, Map.class);
        }
        var items = (List<?>) document.get("items");
        assertThat(items).hasSize(32);

        // The runner executes once at Spring application startup.
        Map<String, UUID> before = new LinkedHashMap<>();
        for (var raw : items) {
            var item = (Map<?, ?>) raw;
            var code = (String) item.get("code");
            var type = (String) item.get("type");
            var id = revisions.findIdByExactIdentity(code, type, 1).orElseThrow();
            var revision = revisions.findById(id).orElseThrow();
            assertThat(revision.getLifecycle().name()).isEqualTo("DRAFT");
            before.put(type + ":" + code, id);
        }

        // Explicit replay must not introduce a second revision or touch Drafts.
        runner.run(null);
        for (var raw : items) {
            var item = (Map<?, ?>) raw;
            var code = (String) item.get("code");
            var type = (String) item.get("type");
            assertThat(revisions.findIdByExactIdentity(code, type, 1))
                    .contains(before.get(type + ":" + code));
        }
    }
}
