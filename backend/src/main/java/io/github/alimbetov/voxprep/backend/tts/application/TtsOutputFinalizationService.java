package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.asset.application.ObjectStoragePort;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import io.github.alimbetov.voxprep.backend.infrastructure.storage.RustFsProperties;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;

@Service
public class TtsOutputFinalizationService {

    public static final String AUDIO_PROFILE = "mp3-mono-24k-64k-v1";
    public static final String CONTENT_TYPE = "audio/mpeg";

    private final JdbcTemplate jdbcTemplate;
    private final ObjectStoragePort objectStorage;
    private final RustFsProperties storageProperties;
    private final TransactionTemplate transactionTemplate;

    public TtsOutputFinalizationService(
            JdbcTemplate jdbcTemplate,
            ObjectStoragePort objectStorage,
            RustFsProperties storageProperties,
            TransactionTemplate transactionTemplate) {
        this.jdbcTemplate = jdbcTemplate;
        this.objectStorage = objectStorage;
        this.storageProperties = storageProperties;
        this.transactionTemplate = transactionTemplate;
    }

    /**
     * Worker-facing engine-fenced output entry point. Engine and Kokoro
     * manifest identity must match the persisted immutable job snapshot
     * BEFORE any RustFS write or READY replay is considered.
     *
     * Existing direct finalizeOutput is retained for internal test fixtures;
     * both V1 and V2 worker controllers use this fenced entry point.
     */
    public FinalizationResult finalizeOutputForEngine(
            OutputUpload upload, TtsEngine expectedEngine, String manifestSha256) {
        Objects.requireNonNull(upload, "upload");
        Objects.requireNonNull(expectedEngine, "expectedEngine");
        Integer compatible = jdbcTemplate.queryForObject("""
                SELECT count(*) FROM app.tts_job j
                JOIN app.tts_voice_model vm ON vm.id = j.voice_model_id
                LEFT JOIN app.tts_kokoro_job_snapshot s ON s.job_id = j.id
                 WHERE j.id = ? AND j.file_id = ? AND j.voice_model_id = ?
                   AND j.fingerprint = ? AND vm.engine = ?
                   AND (vm.engine = 'PIPER'
                        OR (s.voice_model_id = j.voice_model_id
                           AND s.fingerprint = j.fingerprint
                           AND s.manifest_sha256 = ?
                           AND s.fingerprint_version = 'tts-fingerprint-v2'))
                """, Integer.class, upload.jobId(), upload.fileId(),
                upload.voiceModelId(), upload.fingerprint(),
                expectedEngine.name(), manifestSha256);
        if (compatible == null || compatible != 1) {
            return FinalizationResult.REPLAY_MISMATCH;
        }
        return finalizeOutput(upload);
    }

    public FinalizationResult finalizeOutput(OutputUpload upload) {
        validateArtifact(upload);

        FinalizationResult completed = completedState(upload);
        if (completed != null) {
            return completed;
        }
        if (!ownsActiveLease(upload)) {
            return FinalizationResult.LEASE_LOST;
        }

        String objectKey = objectKey(upload);
        objectStorage.write(
                storageProperties.getBucket(),
                objectKey,
                CONTENT_TYPE,
                Map.of(
                        "sha256", upload.sha256(),
                        "fingerprint", upload.fingerprint(),
                        "audio-profile", upload.audioProfile()),
                upload.bytes());

        FinalizationResult result = transactionTemplate.execute(status -> finalizeDatabase(upload, objectKey));
        return Objects.requireNonNull(result, "finalization result");
    }

    private FinalizationResult finalizeDatabase(OutputUpload upload, String objectKey) {
        List<String> statuses = jdbcTemplate.query(
                "SELECT status FROM app.tts_job WHERE id = ? FOR UPDATE",
                (rs, rowNum) -> rs.getString("status"),
                upload.jobId());
        if (statuses.isEmpty()) {
            return FinalizationResult.LEASE_LOST;
        }
        if ("READY".equals(statuses.getFirst())) {
            return exactCompletedUpload(upload)
                    ? FinalizationResult.ALREADY_FINALIZED
                    : FinalizationResult.REPLAY_MISMATCH;
        }
        if (!ownsActiveLease(upload)) {
            return FinalizationResult.LEASE_LOST;
        }

        jdbcTemplate.update("""
                INSERT INTO app.file_asset (
                    id, version, created_at, updated_at, kind, status,
                    bucket, object_key, media_type, size_bytes, sha256,
                    audio_profile, duration_ms)
                VALUES (?, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'TTS_AUDIO', 'READY',
                        ?, ?, ?, ?, ?, ?, ?)
                """,
                upload.fileId(), storageProperties.getBucket(), objectKey, CONTENT_TYPE,
                upload.sizeBytes(), upload.sha256(), upload.audioProfile(), upload.durationMs());

        int updated = jdbcTemplate.update("""
                UPDATE app.tts_job
                   SET status = 'READY',
                       output_asset_id = ?,
                       lease_owner = NULL,
                       lease_token = NULL,
                       lease_until = NULL,
                       finalized_by_worker = ?,
                       finalized_lease_token = ?,
                       finalized_at = CURRENT_TIMESTAMP,
                       version = version + 1,
                       updated_at = CURRENT_TIMESTAMP
                 WHERE id = ?
                   AND file_id = ?
                   AND fingerprint = ?
                   AND voice_model_id = ?
                   AND lease_owner = ?
                   AND lease_token = ?
                   AND status IN ('CLAIMED', 'PROCESSING')
                   AND lease_until >= CURRENT_TIMESTAMP
                """,
                upload.fileId(), upload.workerId(), upload.leaseToken(), upload.jobId(), upload.fileId(),
                upload.fingerprint(), upload.voiceModelId(), upload.workerId(), upload.leaseToken());
        if (updated != 1) {
            throw new IllegalStateException("Locked TTS job lost its lease during finalization");
        }
        return FinalizationResult.CREATED;
    }

    private FinalizationResult completedState(OutputUpload upload) {
        Integer ready = jdbcTemplate.queryForObject(
                "SELECT count(*) FROM app.tts_job WHERE id = ? AND status = 'READY'",
                Integer.class, upload.jobId());
        if (ready == null || ready == 0) {
            return null;
        }
        return exactCompletedUpload(upload)
                ? FinalizationResult.ALREADY_FINALIZED
                : FinalizationResult.REPLAY_MISMATCH;
    }

    private boolean exactCompletedUpload(OutputUpload upload) {
        Integer count = jdbcTemplate.queryForObject("""
                SELECT count(*)
                  FROM app.tts_job j
                  JOIN app.file_asset a ON a.id = j.output_asset_id
                 WHERE j.id = ?
                   AND j.status = 'READY'
                   AND j.file_id = ?
                   AND j.output_asset_id = ?
                   AND j.fingerprint = ?
                   AND j.voice_model_id = ?
                   AND j.finalized_by_worker = ?
                   AND j.finalized_lease_token = ?
                   AND a.kind = 'TTS_AUDIO'
                   AND a.status = 'READY'
                   AND a.media_type = ?
                   AND a.size_bytes = ?
                   AND a.sha256 = ?
                   AND a.audio_profile = ?
                   AND a.duration_ms IS NOT DISTINCT FROM ?
                """, Integer.class,
                upload.jobId(), upload.fileId(), upload.fileId(), upload.fingerprint(), upload.voiceModelId(),
                upload.workerId(), upload.leaseToken(), CONTENT_TYPE, upload.sizeBytes(), upload.sha256(),
                upload.audioProfile(), upload.durationMs());
        return count != null && count == 1;
    }

    private boolean ownsActiveLease(OutputUpload upload) {
        Integer count = jdbcTemplate.queryForObject("""
                SELECT count(*)
                  FROM app.tts_job
                 WHERE id = ?
                   AND file_id = ?
                   AND fingerprint = ?
                   AND voice_model_id = ?
                   AND lease_owner = ?
                   AND lease_token = ?
                   AND status IN ('CLAIMED', 'PROCESSING')
                   AND lease_until >= CURRENT_TIMESTAMP
                """, Integer.class,
                upload.jobId(), upload.fileId(), upload.fingerprint(), upload.voiceModelId(),
                upload.workerId(), upload.leaseToken());
        return count != null && count == 1;
    }

    private static String objectKey(OutputUpload upload) {
        return "tts/audio/" + upload.fileId() + "/" + upload.leaseToken() + ".mp3";
    }

    private static void validateArtifact(OutputUpload upload) {
        Objects.requireNonNull(upload, "upload");
        if (!CONTENT_TYPE.equals(upload.contentType())) {
            throw new IllegalArgumentException("TTS output must be audio/mpeg");
        }
        if (!AUDIO_PROFILE.equals(upload.audioProfile())) {
            throw new IllegalArgumentException("Unsupported TTS audio profile");
        }
        if (upload.sizeBytes() < 1 || upload.sizeBytes() != upload.bytes().length) {
            throw new IllegalArgumentException("TTS output sizeBytes does not match payload");
        }
        if (upload.durationMs() != null && upload.durationMs() < 1) {
            throw new IllegalArgumentException("durationMs must be positive when supplied");
        }
        if (!sha256(upload.bytes()).equals(upload.sha256())) {
            throw new IllegalArgumentException("TTS output SHA-256 does not match payload");
        }
    }

    private static String sha256(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (java.security.NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    public enum FinalizationResult { CREATED, ALREADY_FINALIZED, LEASE_LOST, REPLAY_MISMATCH }

    public record OutputUpload(
            UUID jobId,
            String workerId,
            UUID fileId,
            UUID leaseToken,
            String fingerprint,
            UUID voiceModelId,
            String audioProfile,
            String sha256,
            long sizeBytes,
            Long durationMs,
            String contentType,
            byte[] bytes) {

        public OutputUpload {
            Objects.requireNonNull(jobId, "jobId");
            workerId = required(workerId, "workerId", 128);
            Objects.requireNonNull(fileId, "fileId");
            Objects.requireNonNull(leaseToken, "leaseToken");
            fingerprint = digest(fingerprint, "fingerprint");
            Objects.requireNonNull(voiceModelId, "voiceModelId");
            audioProfile = required(audioProfile, "audioProfile", 128);
            sha256 = digest(sha256, "sha256");
            contentType = required(contentType, "contentType", 128);
            bytes = Objects.requireNonNull(bytes, "bytes");
        }

        private static String required(String value, String field, int maxLength) {
            Objects.requireNonNull(value, field);
            String normalized = value.strip();
            if (normalized.isEmpty() || !normalized.equals(value) || value.length() > maxLength) {
                throw new IllegalArgumentException("Invalid " + field);
            }
            return value;
        }

        private static String digest(String value, String field) {
            value = required(value, field, 64);
            if (!value.matches("[0-9a-f]{64}")) {
                throw new IllegalArgumentException(field + " must be lowercase SHA-256");
            }
            return value;
        }
    }
}
