package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.infrastructure.storage.RustFsProperties;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.HexFormat;
import java.util.Objects;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

@Service
public class TtsOutputFinalizationService {

    public static final String AUDIO_PROFILE = "mp3-mono-24k-64k-v1";
    public static final String CONTENT_TYPE = "audio/mpeg";

    private final JdbcTemplate jdbcTemplate;
    private final S3Client s3Client;
    private final RustFsProperties storageProperties;
    private final TransactionTemplate transactionTemplate;

    public TtsOutputFinalizationService(
            JdbcTemplate jdbcTemplate,
            S3Client s3Client,
            RustFsProperties storageProperties,
            TransactionTemplate transactionTemplate) {
        this.jdbcTemplate = jdbcTemplate;
        this.s3Client = s3Client;
        this.storageProperties = storageProperties;
        this.transactionTemplate = transactionTemplate;
    }

    public FinalizationResult finalizeOutput(OutputUpload upload) {
        validateArtifact(upload);
        if (!ownsActiveLease(upload)) {
            return FinalizationResult.LEASE_LOST;
        }

        String objectKey = "tts/audio/" + upload.fileId() + "/" + upload.leaseToken() + ".mp3";
        s3Client.putObject(
                PutObjectRequest.builder()
                        .bucket(storageProperties.getBucket())
                        .key(objectKey)
                        .contentType(CONTENT_TYPE)
                        .metadata(java.util.Map.of(
                                "sha256", upload.sha256(),
                                "fingerprint", upload.fingerprint(),
                                "audio-profile", upload.audioProfile()))
                        .build(),
                RequestBody.fromBytes(upload.bytes()));

        Boolean finalized = transactionTemplate.execute(status -> {
            if (!ownsActiveLease(upload)) {
                return false;
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
                    upload.fileId(), upload.jobId(), upload.fileId(), upload.fingerprint(),
                    upload.voiceModelId(), upload.workerId(), upload.leaseToken());
            if (updated != 1) {
                status.setRollbackOnly();
                return false;
            }
            return true;
        });
        return Boolean.TRUE.equals(finalized) ? FinalizationResult.CREATED : FinalizationResult.LEASE_LOST;
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
        String actual = sha256(upload.bytes());
        if (!actual.equals(upload.sha256())) {
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

    public enum FinalizationResult { CREATED, LEASE_LOST }

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
