package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.tts.domain.TtsJobStatus;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
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
                SELECT j.id FROM app.tts_job j
                  JOIN app.tts_voice_model vm ON vm.id = j.voice_model_id
                 WHERE vm.engine = 'PIPER'
                   AND (j.status = 'PENDING'
                        OR (j.status IN ('CLAIMED', 'PROCESSING')
                            AND j.lease_until < CURRENT_TIMESTAMP))
                 ORDER BY j.created_at, j.id
                 FOR UPDATE OF j SKIP LOCKED LIMIT 1
            )
            UPDATE app.tts_job AS job
               SET status = 'CLAIMED', lease_owner = ?, lease_token = ?, lease_until = ?,
                   claimed_at = COALESCE(job.claimed_at, CURRENT_TIMESTAMP),
                   attempt_count = job.attempt_count + 1, version = job.version + 1,
                   updated_at = CURRENT_TIMESTAMP
              FROM candidate WHERE job.id = candidate.id
            RETURNING job.id, job.voice_model_id, job.input_text, job.input_sha256,
                      job.lease_owner, job.lease_token, job.lease_until, job.attempt_count
            """;

    private static final String WORKER_CLAIM_SQL = """
            WITH candidate AS (
                SELECT j.id FROM app.tts_job j
                  JOIN app.tts_voice_model vm ON vm.id = j.voice_model_id
                 WHERE j.file_id IS NOT NULL
                   AND vm.engine = 'PIPER'
                   AND (j.status = 'PENDING'
                        OR (j.status IN ('CLAIMED', 'PROCESSING')
                            AND j.lease_until < CURRENT_TIMESTAMP))
                 ORDER BY j.created_at, j.id
                 FOR UPDATE OF j SKIP LOCKED LIMIT 1
            ), claimed AS (
                UPDATE app.tts_job AS job
                   SET status = 'CLAIMED', lease_owner = ?, lease_token = ?, lease_until = ?,
                       claimed_at = COALESCE(job.claimed_at, CURRENT_TIMESTAMP),
                       attempt_count = job.attempt_count + 1, version = job.version + 1,
                       updated_at = CURRENT_TIMESTAMP
                  FROM candidate WHERE job.id = candidate.id
                RETURNING job.id, job.file_id, job.content_revision_id, job.audio_role,
                          job.normalized_tts_text, job.language, job.voice_model_id,
                          job.fingerprint, job.lease_token, job.lease_until
            )
            SELECT c.id, c.file_id, c.content_revision_id, c.audio_role,
                   c.normalized_tts_text, c.language, c.voice_model_id,
                   vm.code AS voice_model_code, vm.model_sha256, vm.config_sha256,
                   c.fingerprint, c.lease_token, c.lease_until
              FROM claimed c
              JOIN app.tts_voice_model vm ON vm.id = c.voice_model_id
            """;

    private static final String ENGINE_SCOPED_CLAIM_SQL = """
            WITH candidate AS (
                SELECT j.id FROM app.tts_job j
                  JOIN app.tts_voice_model vm ON vm.id = j.voice_model_id
                 WHERE j.file_id IS NOT NULL
                   AND vm.engine = ?
                   AND (j.status = 'PENDING'
                        OR (j.status IN ('CLAIMED', 'PROCESSING')
                            AND j.lease_until < CURRENT_TIMESTAMP))
                 ORDER BY j.created_at, j.id
                 FOR UPDATE OF j SKIP LOCKED LIMIT 1
            ), claimed AS (
                UPDATE app.tts_job AS job
                   SET status = 'CLAIMED', lease_owner = ?, lease_token = ?, lease_until = ?,
                       claimed_at = COALESCE(job.claimed_at, CURRENT_TIMESTAMP),
                       attempt_count = job.attempt_count + 1, version = job.version + 1,
                       updated_at = CURRENT_TIMESTAMP
                  FROM candidate WHERE job.id = candidate.id
                RETURNING job.id, job.file_id, job.content_revision_id, job.audio_role,
                          job.normalized_tts_text, job.language, job.voice_model_id,
                          job.fingerprint, job.lease_token, job.lease_until
            )
            SELECT c.id, c.file_id, c.content_revision_id, c.audio_role,
                   c.normalized_tts_text, c.language, c.voice_model_id,
                   vm.code AS voice_model_code, vm.model_sha256, vm.config_sha256,
                   c.fingerprint, c.lease_token, c.lease_until
              FROM claimed c
              JOIN app.tts_voice_model vm ON vm.id = c.voice_model_id
            """;

    private final JdbcTemplate jdbcTemplate;

    public TtsJobLeaseService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Transactional
    public Optional<TtsJobLeaseClaim> claimNext(String workerId, Duration leaseDuration) {
        String leaseOwner = required(workerId, "workerId", 128);
        Duration duration = positiveDuration(leaseDuration);
        UUID leaseToken = UUID.randomUUID();
        Instant leaseUntil = Instant.now().plus(duration);
        List<TtsJobLeaseClaim> claims = jdbcTemplate.query(
                CLAIM_SQL,
                (rs, rowNum) -> new TtsJobLeaseClaim(
                        rs.getObject("id", UUID.class), rs.getObject("voice_model_id", UUID.class),
                        rs.getString("input_text"), rs.getString("input_sha256"),
                        rs.getString("lease_owner"), rs.getObject("lease_token", UUID.class),
                        rs.getTimestamp("lease_until").toInstant(), rs.getInt("attempt_count")),
                leaseOwner, leaseToken, Timestamp.from(leaseUntil));
        return claims.stream().findFirst();
    }

    @Transactional
    public Optional<WorkerTtsJobClaim> claimNextForWorker(String workerId, Duration leaseDuration) {
        String leaseOwner = required(workerId, "workerId", 128);
        Duration duration = positiveDuration(leaseDuration);
        UUID leaseToken = UUID.randomUUID();
        Instant leaseUntil = Instant.now().plus(duration);
        return jdbcTemplate.query(
                WORKER_CLAIM_SQL,
                (rs, rowNum) -> new WorkerTtsJobClaim(
                        rs.getObject("id", UUID.class),
                        rs.getObject("file_id", UUID.class),
                        rs.getObject("content_revision_id", UUID.class),
                        rs.getString("audio_role"),
                        rs.getString("normalized_tts_text"),
                        rs.getString("language"),
                        rs.getObject("voice_model_id", UUID.class),
                        rs.getString("voice_model_code"),
                        rs.getString("model_sha256"),
                        rs.getString("config_sha256"),
                        rs.getString("fingerprint"),
                        rs.getObject("lease_token", UUID.class),
                        rs.getTimestamp("lease_until").toInstant()),
                leaseOwner, leaseToken, Timestamp.from(leaseUntil)).stream().findFirst();
    }

    /**
     * Engine-scoped atomic claim for authenticated V2 workers. The caller MUST
     * derive the engine from a verified credential, not from request JSON.
     */
    @Transactional
    public Optional<WorkerTtsJobClaim> claimNextForEngine(
            String workerId, TtsEngine engine, Duration leaseDuration) {
        String leaseOwner = required(workerId, "workerId", 128);
        Objects.requireNonNull(engine, "engine");
        Duration duration = positiveDuration(leaseDuration);
        UUID leaseToken = UUID.randomUUID();
        Instant leaseUntil = Instant.now().plus(duration);
        return jdbcTemplate.query(
                ENGINE_SCOPED_CLAIM_SQL,
                (rs, rowNum) -> new WorkerTtsJobClaim(
                        rs.getObject("id", UUID.class),
                        rs.getObject("file_id", UUID.class),
                        rs.getObject("content_revision_id", UUID.class),
                        rs.getString("audio_role"),
                        rs.getString("normalized_tts_text"),
                        rs.getString("language"),
                        rs.getObject("voice_model_id", UUID.class),
                        rs.getString("voice_model_code"),
                        rs.getString("model_sha256"),
                        rs.getString("config_sha256"),
                        rs.getString("fingerprint"),
                        rs.getObject("lease_token", UUID.class),
                        rs.getTimestamp("lease_until").toInstant()),
                engine.name(), leaseOwner, leaseToken, Timestamp.from(leaseUntil))
                .stream().findFirst();
    }

    /**
     * Claims ONLY complete KOKORO jobs whose pinned model snapshot is present.
     * Engine, job fingerprint and approved voice-model identity are checked
     * inside the same atomic PostgreSQL lock/update.
     */
    @Transactional
    public Optional<KokoroWorkerTtsJobClaim> claimNextKokoroForWorker(
            String workerId, Duration leaseDuration) {
        String leaseOwner = required(workerId, "workerId", 128);
        UUID token = UUID.randomUUID();
        Instant expires = Instant.now().plus(positiveDuration(leaseDuration));
        return jdbcTemplate.query("""
                WITH candidate AS (
                    SELECT j.id
                      FROM app.tts_job j
                      JOIN app.tts_voice_model vm ON vm.id = j.voice_model_id
                      JOIN app.tts_kokoro_job_snapshot s
                        ON s.job_id = j.id AND s.voice_model_id = vm.id
                           AND s.fingerprint = j.fingerprint
                      JOIN app.tts_kokoro_bundle b ON b.id = s.bundle_id
                           AND b.manifest_sha256 = s.manifest_sha256
                     WHERE j.file_id IS NOT NULL
                       AND vm.engine = 'KOKORO'
                       AND vm.status = 'ACTIVE'
                       AND vm.commercial_use_reviewed = TRUE
                       AND b.status = 'STAGED'
                       AND (j.status = 'PENDING'
                          OR (j.status IN ('CLAIMED', 'PROCESSING')
                              AND j.lease_until < CURRENT_TIMESTAMP))
                     ORDER BY j.created_at, j.id
                     FOR UPDATE OF j SKIP LOCKED LIMIT 1
                ), claimed AS (
                    UPDATE app.tts_job j
                       SET status = 'CLAIMED', lease_owner = ?,
                           lease_token = ?, lease_until = ?,
                           claimed_at = COALESCE(j.claimed_at, CURRENT_TIMESTAMP),
                           attempt_count = j.attempt_count + 1,
                           version = j.version + 1, updated_at = CURRENT_TIMESTAMP
                      FROM candidate WHERE j.id = candidate.id
                    RETURNING j.id, j.file_id, j.content_revision_id,
                              j.audio_role, j.normalized_tts_text, j.language,
                              j.voice_model_id, j.fingerprint,
                              j.lease_token, j.lease_until
                )
                SELECT c.*, vm.code AS voice_model_code,
                       b.model_code AS bundle_model_code,
                       s.bundle_id, s.manifest_sha256, s.voice_code,
                       s.voice_artifact_sha256, s.phonemizer_version,
                       s.engine_version, s.speed
                  FROM claimed c
                  JOIN app.tts_voice_model vm ON vm.id = c.voice_model_id
                  JOIN app.tts_kokoro_job_snapshot s ON s.job_id = c.id
                  JOIN app.tts_kokoro_bundle b ON b.id = s.bundle_id
                """, (rs, row) -> new KokoroWorkerTtsJobClaim(
                        new WorkerTtsJobClaim(
                                rs.getObject("id", UUID.class),
                                rs.getObject("file_id", UUID.class),
                                rs.getObject("content_revision_id", UUID.class),
                                rs.getString("audio_role"),
                                rs.getString("normalized_tts_text"),
                                rs.getString("language"),
                                rs.getObject("voice_model_id", UUID.class),
                                rs.getString("voice_model_code"),
                                null, null,
                                rs.getString("fingerprint"),
                                rs.getObject("lease_token", UUID.class),
                                rs.getTimestamp("lease_until").toInstant()),
                        rs.getObject("bundle_id", UUID.class),
                        rs.getString("bundle_model_code"),
                        rs.getString("manifest_sha256"),
                        rs.getString("voice_code"),
                        rs.getString("voice_artifact_sha256"),
                        rs.getString("phonemizer_version"),
                        rs.getString("engine_version"),
                        rs.getBigDecimal("speed")),
                leaseOwner, token, Timestamp.from(expires)).stream().findFirst();
    }

    @Transactional
    public Optional<TtsJobLeaseState> heartbeat(UUID jobId, String workerId, UUID leaseToken, Duration leaseDuration) {
        Objects.requireNonNull(jobId, "jobId");
        String leaseOwner = required(workerId, "workerId", 128);
        Objects.requireNonNull(leaseToken, "leaseToken");
        Instant leaseUntil = Instant.now().plus(positiveDuration(leaseDuration));
        return jdbcTemplate.query("""
                        UPDATE app.tts_job
                           SET status = 'PROCESSING', lease_until = ?, version = version + 1,
                               updated_at = CURRENT_TIMESTAMP
                         WHERE id = ? AND lease_owner = ? AND lease_token = ?
                           AND status IN ('CLAIMED', 'PROCESSING')
                           AND lease_until >= CURRENT_TIMESTAMP
                        RETURNING id, status, lease_owner, lease_token, lease_until, attempt_count
                        """,
                (rs, rowNum) -> new TtsJobLeaseState(
                        rs.getObject("id", UUID.class), TtsJobStatus.valueOf(rs.getString("status")),
                        rs.getString("lease_owner"), rs.getObject("lease_token", UUID.class),
                        rs.getTimestamp("lease_until").toInstant(), rs.getInt("attempt_count")),
                Timestamp.from(leaseUntil), jobId, leaseOwner, leaseToken).stream().findFirst();
    }

    /**
     * V2 heartbeat checks the authenticated engine in the UPDATE predicate.
     * Legacy Piper heartbeat contract remains unchanged.
     */
    @Transactional
    public Optional<TtsJobLeaseState> heartbeatForEngine(
            UUID jobId, String workerId, UUID leaseToken,
            TtsEngine engine, Duration leaseDuration) {
        Objects.requireNonNull(jobId, "jobId");
        String owner = required(workerId, "workerId", 128);
        Objects.requireNonNull(leaseToken, "leaseToken");
        Objects.requireNonNull(engine, "engine");
        Instant until = Instant.now().plus(positiveDuration(leaseDuration));
        return jdbcTemplate.query("""
                UPDATE app.tts_job AS j
                   SET status = 'PROCESSING', lease_until = ?, version = j.version + 1,
                       updated_at = CURRENT_TIMESTAMP
                 WHERE j.id = ? AND j.lease_owner = ? AND j.lease_token = ?
                   AND j.status IN ('CLAIMED', 'PROCESSING')
                   AND j.lease_until >= CURRENT_TIMESTAMP
                   AND EXISTS (
                       SELECT 1 FROM app.tts_voice_model vm
                       WHERE vm.id = j.voice_model_id AND vm.engine = ?
                   )
                RETURNING j.id, j.status, j.lease_owner, j.lease_token,
                          j.lease_until, j.attempt_count
                """,
                (rs, rowNum) -> new TtsJobLeaseState(
                        rs.getObject("id", UUID.class),
                        TtsJobStatus.valueOf(rs.getString("status")),
                        rs.getString("lease_owner"),
                        rs.getObject("lease_token", UUID.class),
                        rs.getTimestamp("lease_until").toInstant(),
                        rs.getInt("attempt_count")),
                Timestamp.from(until), jobId, owner, leaseToken, engine.name()
        ).stream().findFirst();
    }

    /** V2 failure transition enforces engine and current lease atomically. */
    @Transactional
    public boolean failWorkerForEngine(
            UUID jobId, UUID fileId, String workerId, UUID leaseToken,
            TtsEngine engine, String failureCode, String failureMessage) {
        Objects.requireNonNull(jobId, "jobId");
        Objects.requireNonNull(fileId, "fileId");
        String owner = required(workerId, "workerId", 128);
        Objects.requireNonNull(leaseToken, "leaseToken");
        Objects.requireNonNull(engine, "engine");
        String code = required(failureCode, "failureCode", 64);
        String message = optional(failureMessage, "failureMessage", 2000);
        return jdbcTemplate.update("""
                UPDATE app.tts_job AS j
                   SET status = 'FAILED', lease_owner = NULL, lease_token = NULL,
                       lease_until = NULL, failure_code = ?, failure_message = ?,
                       failed_at = CURRENT_TIMESTAMP,
                       version = j.version + 1, updated_at = CURRENT_TIMESTAMP
                 WHERE j.id = ? AND j.file_id = ?
                   AND j.lease_owner = ? AND j.lease_token = ?
                   AND j.status IN ('CLAIMED', 'PROCESSING')
                   AND j.lease_until >= CURRENT_TIMESTAMP
                   AND EXISTS (
                       SELECT 1 FROM app.tts_voice_model vm
                       WHERE vm.id = j.voice_model_id AND vm.engine = ?
                   )
                """, code, message, jobId, fileId, owner, leaseToken, engine.name()) == 1;
    }

    @Transactional
    public boolean fail(UUID jobId, String workerId, UUID leaseToken, String failureCode, String failureMessage) {
        return failInternal(jobId, null, workerId, leaseToken, failureCode, failureMessage);
    }

    @Transactional
    public boolean failWorker(UUID jobId, UUID fileId, String workerId, UUID leaseToken,
            String failureCode, String failureMessage) {
        Objects.requireNonNull(fileId, "fileId");
        return failInternal(jobId, fileId, workerId, leaseToken, failureCode, failureMessage);
    }

    private boolean failInternal(UUID jobId, UUID fileId, String workerId, UUID leaseToken,
            String failureCode, String failureMessage) {
        Objects.requireNonNull(jobId, "jobId");
        String leaseOwner = required(workerId, "workerId", 128);
        Objects.requireNonNull(leaseToken, "leaseToken");
        String code = required(failureCode, "failureCode", 64);
        String message = optional(failureMessage, "failureMessage", 2000);
        String filePredicate = fileId == null ? "" : " AND file_id = ?";
        String sql = """
                UPDATE app.tts_job
                   SET status = 'FAILED', lease_owner = NULL, lease_token = NULL, lease_until = NULL,
                       failure_code = ?, failure_message = ?, failed_at = CURRENT_TIMESTAMP,
                       version = version + 1, updated_at = CURRENT_TIMESTAMP
                 WHERE id = ? AND lease_owner = ? AND lease_token = ?
                   AND status IN ('CLAIMED', 'PROCESSING')
                   AND lease_until >= CURRENT_TIMESTAMP
                """ + filePredicate;
        int updated = fileId == null
                ? jdbcTemplate.update(sql, code, message, jobId, leaseOwner, leaseToken)
                : jdbcTemplate.update(sql, code, message, jobId, leaseOwner, leaseToken, fileId);
        return updated == 1;
    }

    private static Duration positiveDuration(Duration value) {
        Objects.requireNonNull(value, "leaseDuration");
        if (value.isZero() || value.isNegative()) throw new IllegalArgumentException("leaseDuration must be positive");
        return value;
    }

    private static String required(String value, String field, int maxLength) {
        Objects.requireNonNull(value, field);
        String normalized = value.strip();
        if (normalized.isEmpty()) throw new IllegalArgumentException(field + " must not be blank");
        if (!normalized.equals(value)) throw new IllegalArgumentException(field + " must not contain surrounding whitespace");
        if (value.length() > maxLength) throw new IllegalArgumentException(field + " exceeds max length " + maxLength);
        return value;
    }

    private static String optional(String value, String field, int maxLength) {
        return value == null ? null : required(value, field, maxLength);
    }
}
