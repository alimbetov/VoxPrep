package io.github.alimbetov.voxprep.backend.tts.application;

import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TtsJobLeaseService {

    private static final String CLAIM_SQL = """
            WITH candidate AS (
                SELECT id
                  FROM app.tts_job
                 WHERE status = 'PENDING'
                    OR (status IN ('CLAIMED', 'PROCESSING') AND lease_until < CURRENT_TIMESTAMP)
                 ORDER BY created_at, id
                 FOR UPDATE SKIP LOCKED
                 LIMIT 1
            )
            UPDATE app.tts_job AS job
               SET status = 'CLAIMED',
                   lease_owner = ?,
                   lease_token = ?,
                   lease_until = ?,
                   claimed_at = COALESCE(job.claimed_at, CURRENT_TIMESTAMP),
                   attempt_count = job.attempt_count + 1,
                   version = job.version + 1,
                   updated_at = CURRENT_TIMESTAMP
              FROM candidate
             WHERE job.id = candidate.id
            RETURNING job.id,
                      job.voice_model_id,
                      job.input_text,
                      job.input_sha256,
                      job.lease_owner,
                      job.lease_token,
                      job.lease_until,
                      job.attempt_count
            """;

    private final JdbcTemplate jdbcTemplate;

    public TtsJobLeaseService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Transactional
    public Optional<TtsJobLeaseClaim> claimNext(String workerId, Duration leaseDuration) {
        String leaseOwner = required(workerId, "workerId", 128);
        Objects.requireNonNull(leaseDuration, "leaseDuration");
        if (leaseDuration.isZero() || leaseDuration.isNegative()) {
            throw new IllegalArgumentException("leaseDuration must be positive");
        }

        UUID leaseToken = UUID.randomUUID();
        Instant leaseUntil = Instant.now().plus(leaseDuration);
        List<TtsJobLeaseClaim> claims = jdbcTemplate.query(
                CLAIM_SQL,
                (rs, rowNum) -> new TtsJobLeaseClaim(
                        rs.getObject("id", UUID.class),
                        rs.getObject("voice_model_id", UUID.class),
                        rs.getString("input_text"),
                        rs.getString("input_sha256"),
                        rs.getString("lease_owner"),
                        rs.getObject("lease_token", UUID.class),
                        rs.getTimestamp("lease_until").toInstant(),
                        rs.getInt("attempt_count")),
                leaseOwner,
                leaseToken,
                Timestamp.from(leaseUntil));
        return claims.stream().findFirst();
    }

    private static String required(String value, String field, int maxLength) {
        Objects.requireNonNull(value, field);
        String normalized = value.strip();
        if (normalized.isEmpty()) {
            throw new IllegalArgumentException(field + " must not be blank");
        }
        if (!normalized.equals(value)) {
            throw new IllegalArgumentException(field + " must not contain surrounding whitespace");
        }
        if (value.length() > maxLength) {
            throw new IllegalArgumentException(field + " exceeds max length " + maxLength);
        }
        return value;
    }
}
