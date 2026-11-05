package io.github.alimbetov.voxprep.backend.content.dev;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.application.ContentAuthoringService;
import io.github.alimbetov.voxprep.backend.content.application.ContentDraftUpdate;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.ShadowingSegmentEmbeddable;
import io.github.alimbetov.voxprep.backend.content.persistence.TopicSectionEmbeddable;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Profile;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Component;
import tools.jackson.databind.ObjectMapper;

/**
 * Explicit opt-in local seed, using normal ContentAuthoringService writes.
 * The component is not registered in staging/test/production, never auto-publishes
 * and never generates payment claims. Existing revisions are left untouched.
 */
@Component
@Profile("dev")
@ConditionalOnProperty(prefix = "voxprep.dev", name = "demo-seed-enabled", havingValue = "true")
public final class DemoCatalogueSeedRunner implements ApplicationRunner {
    private final ContentAuthoringService authoring;
    private final ContentRevisionRepository revisions;
    private final ObjectMapper json;
    private final Resource fixture;

    public DemoCatalogueSeedRunner(ContentAuthoringService authoring,
            ContentRevisionRepository revisions, ObjectMapper json,
            @Value("classpath:dev-fixtures/demo_catalogue_seed.json") Resource fixture) {
        this.authoring = authoring;
        this.revisions = revisions;
        this.json = json;
        this.fixture = fixture;
    }

    @Override
    public void run(org.springframework.boot.ApplicationArguments args) throws Exception {
        Map<?, ?> doc;
        try (var input = fixture.getInputStream()) {
            doc = json.readValue(input, Map.class);
        }
        if (!"voxprep-dev-test".equals(doc.get("fixture"))
                || !(doc.get("schemaVersion") instanceof Number schema)
                || schema.intValue() != 1
                || !(doc.get("items") instanceof List<?> items)
                || items.isEmpty() || items.size() > 200) {
            throw new IllegalStateException("Unsupported or malformed DEV demo seed fixture");
        }
        for (var raw : items) {
            if (!(raw instanceof Map<?, ?> item)) {
                throw new IllegalStateException("Invalid DEV demo seed item");
            }
            String code = string(item, "code");
            String type = string(item, "type");
            if (revisions.findIdByExactIdentity(code, type, 1).isPresent()) {
                continue; // Idempotent: never overwrite a human-edited draft.
            }
            String title = string(item, "title");
            String subtitle = string(item, "subtitle");
            String description = string(item, "description");
            int minutes = ((Number) item.get("minutes")).intValue();
            var update = new ContentDraftUpdate(
                    hash(type + "\n" + code + "\n" + title + "\n" + description),
                    title, subtitle, description,
                    new CatalogueCode(string(item, "category")
                            .toUpperCase(Locale.ROOT).replaceAll("[^A-Z0-9]+", "_")
                            .replaceAll("^_|_$", "")),
                    new CatalogueCode(string(item, "level")),
                    minutes, List.of(new CatalogueCode("SPEAKING")),
                    AvailabilityStatus.ACTIVE,
                    body(type, title, description));
            authoring.createInitialRevision(new BusinessCode(code), update);
        }
    }

    private static ContentDraftUpdate.Body body(String type, String title, String description) {
        return switch (type) {
            case "vocabulary" -> new ContentDraftUpdate.VocabularyBody(
                    title, description, "noun", List.of(description));
            case "interview" -> new ContentDraftUpdate.InterviewBody(
                    title, description, List.of("Explain the concept clearly."));
            case "topic" -> new ContentDraftUpdate.TopicBody(
                    List.of(new TopicSectionEmbeddable("Overview", description)));
            case "phrase" -> new ContentDraftUpdate.PhraseBody(
                    title, description, List.of(title));
            case "shadowing" -> new ContentDraftUpdate.ShadowingBody(
                    description, List.of(new ShadowingSegmentEmbeddable(description, 0, 3000)));
            default -> throw new IllegalStateException("Unsupported DEV demo content type: " + type);
        };
    }

    private static String string(Map<?, ?> item, String key) {
        Object value = item.get(key);
        if (!(value instanceof String text) || text.isBlank()) {
            throw new IllegalStateException("DEV fixture field missing: " + key);
        }
        return text;
    }

    private static Sha256Digest hash(String text) {
        try {
            return new Sha256Digest(HexFormat.of().formatHex(
                    MessageDigest.getInstance("SHA-256")
                            .digest(text.getBytes(StandardCharsets.UTF_8))));
        } catch (java.security.NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 unavailable", ex);
        }
    }
}
