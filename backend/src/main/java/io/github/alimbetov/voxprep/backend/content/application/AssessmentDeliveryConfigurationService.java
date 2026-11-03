package io.github.alimbetov.voxprep.backend.content.application;

import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.PracticeTestContentRevisionEntity;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.ObjectMapper;

/**
 * Explicit editor-owned assessment mode and points. No guessed point weights.
 * The published API consumes a separate immutable ASSESSMENT wire snapshot.
 */
@Service
public class AssessmentDeliveryConfigurationService {

    private static final Set<String> MODES = Set.of("learn", "exam", "quick");
    private final JdbcTemplate jdbc;
    private final ObjectMapper json;
    private final ContentRevisionRepository revisions;

    public AssessmentDeliveryConfigurationService(
            JdbcTemplate jdbc,
            ObjectMapper json,
            ContentRevisionRepository revisions) {
        this.jdbc = Objects.requireNonNull(jdbc);
        this.json = Objects.requireNonNull(json);
        this.revisions = Objects.requireNonNull(revisions);
    }

    @Transactional
    public DeliveryConfiguration configure(UUID testRevisionId, String mode, List<Integer> points) {
        Objects.requireNonNull(testRevisionId, "testRevisionId");
        revisions.lockRevisionIdForUpdate(testRevisionId)
                .orElseThrow(() -> new IllegalArgumentException("assessment revision is missing"));
        var raw = revisions.findById(testRevisionId)
                .orElseThrow(() -> new IllegalArgumentException("assessment revision is missing"));
        if (!(raw instanceof PracticeTestContentRevisionEntity test)) {
            throw new IllegalArgumentException("assessment revision must be a practice test");
        }
        if (test.getPublishedAt() != null) {
            throw new IllegalStateException("published assessment delivery metadata is immutable");
        }
        var config = validate(mode, points, test.getQuestionRevisionIds().size());
        jdbc.update("""
                INSERT INTO app.assessment_delivery_config(test_revision_id, mode, points_json)
                VALUES (?, ?, CAST(? AS jsonb))
                ON CONFLICT (test_revision_id)
                DO UPDATE SET mode = EXCLUDED.mode,
                              points_json = EXCLUDED.points_json,
                              updated_at = now()
                """,
                testRevisionId, config.mode(), serialize(config.points()));
        return config;
    }

    @Transactional(readOnly = true)
    public DeliveryConfiguration requireReady(UUID testRevisionId, int questionCount) {
        List<DeliveryConfiguration> values = jdbc.query("""
                SELECT mode, points_json::text
                  FROM app.assessment_delivery_config
                 WHERE test_revision_id = ?
                """, (rs, index) -> {
            try {
                @SuppressWarnings("unchecked")
                List<Object> raw = json.readValue(rs.getString(2), List.class);
                var points = raw.stream().map(value -> {
                    if (!(value instanceof Integer number)) {
                        throw new IllegalStateException("assessment question points are not integers");
                    }
                    return number;
                }).toList();
                return validate(rs.getString(1), points, questionCount);
            } catch (IllegalStateException exception) {
                throw exception;
            } catch (Exception exception) {
                throw new IllegalStateException("cannot deserialize assessment delivery metadata", exception);
            }
        }, testRevisionId);
        if (values.size() != 1) {
            throw new IllegalStateException("approved practice test lacks explicit mode/points metadata");
        }
        return values.get(0);
    }

    private static DeliveryConfiguration validate(String mode, List<Integer> points, int expectedCount) {
        if (mode == null || !MODES.contains(mode)) {
            throw new IllegalArgumentException("assessment mode must be learn, exam, or quick");
        }
        if (points == null || points.size() != expectedCount || points.isEmpty()
                || points.stream().anyMatch(value -> value == null || value < 1 || value > 10000)) {
            throw new IllegalArgumentException("assessment points must match questions, each within 1..10000");
        }
        return new DeliveryConfiguration(mode, List.copyOf(points));
    }

    private String serialize(List<Integer> points) {
        try {
            return json.writeValueAsString(points);
        } catch (Exception exception) {
            throw new IllegalStateException("cannot serialize assessment delivery metadata", exception);
        }
    }

    public record DeliveryConfiguration(String mode, List<Integer> points) {
        public DeliveryConfiguration {
            points = List.copyOf(points);
        }
    }
}
