package io.github.alimbetov.voxprep.backend.publication.application;

import java.util.Objects;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Allocates learner-visible publication versions from a PostgreSQL sequence.
 * Sequence values are intentionally never recycled, including after transaction rollback.
 */
@Component
public class PublicationContentVersionAllocator {

    private final JdbcTemplate jdbcTemplate;

    public PublicationContentVersionAllocator(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = Objects.requireNonNull(jdbcTemplate, "jdbcTemplate");
    }

    public long nextVersion() {
        Long value = jdbcTemplate.queryForObject(
                "select nextval('app.publication_content_version_seq')", Long.class);
        if (value == null || value <= 0) {
            throw new IllegalStateException("publication content version sequence returned invalid value");
        }
        return value;
    }
}
