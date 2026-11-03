package io.github.alimbetov.voxprep.backend.tts.persistence;

import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.infrastructure.persistence.AbstractJpaEntity;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsJobStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

@Entity
@Table(name = "tts_job", schema = "app")
public class TtsJobEntity extends AbstractJpaEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "voice_model_id", nullable = false, updatable = false)
    private TtsVoiceModelEntity voiceModel;

    @Column(name = "input_text", nullable = false, updatable = false, length = 10000)
    private String inputText;

    @Column(name = "input_sha256", nullable = false, updatable = false, length = 64)
    private String inputSha256;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 32)
    private TtsJobStatus status;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "output_asset_id")
    private FileAssetEntity outputAsset;

    @Column(name = "attempt_count", nullable = false)
    private int attemptCount;

    @Column(name = "lease_owner", length = 128)
    private String leaseOwner;

    @Column(name = "lease_token")
    private UUID leaseToken;

    @Column(name = "lease_until")
    private Instant leaseUntil;

    @Column(name = "claimed_at")
    private Instant claimedAt;

    @Column(name = "failure_code", length = 64)
    private String failureCode;

    @Column(name = "failure_message", length = 2000)
    private String failureMessage;

    @Column(name = "failed_at")
    private Instant failedAt;

    @Column(name = "file_id", updatable = false)
    private UUID fileId;

    @Column(name = "content_revision_id", updatable = false)
    private UUID contentRevisionId;

    @Column(name = "audio_role", updatable = false, length = 64)
    private String audioRole;

    @Column(name = "normalized_tts_text", updatable = false, columnDefinition = "text")
    private String normalizedTtsText;

    @Column(name = "language", updatable = false, length = 64)
    private String language;

    @Column(name = "fingerprint", updatable = false, length = 64)
    private String fingerprint;

    protected TtsJobEntity() {
    }

    public TtsJobEntity(TtsVoiceModelEntity voiceModel, String inputText, String inputSha256) {
        this.voiceModel = Objects.requireNonNull(voiceModel, "voiceModel");
        this.inputText = required(inputText, "inputText", 10000);
        this.inputSha256 = sha256(inputSha256, "inputSha256");
        this.status = TtsJobStatus.PENDING;
    }

    public void prepareWorkerClaim(
            UUID fileId,
            UUID contentRevisionId,
            String audioRole,
            String normalizedTtsText,
            String language,
            String fingerprint) {
        if (this.fileId != null) {
            throw new IllegalStateException("Worker claim snapshot is already assigned");
        }
        if (status != TtsJobStatus.PENDING) {
            throw new IllegalStateException("Worker claim snapshot can only be assigned to PENDING jobs");
        }
        this.fileId = Objects.requireNonNull(fileId, "fileId");
        this.contentRevisionId = Objects.requireNonNull(contentRevisionId, "contentRevisionId");
        this.audioRole = required(audioRole, "audioRole", 64);
        this.normalizedTtsText = required(normalizedTtsText, "normalizedTtsText", 10000);
        this.language = required(language, "language", 64);
        this.fingerprint = sha256(fingerprint, "fingerprint");
    }

    public TtsVoiceModelEntity getVoiceModel() { return voiceModel; }
    public String getInputText() { return inputText; }
    public String getInputSha256() { return inputSha256; }
    public TtsJobStatus getStatus() { return status; }
    public FileAssetEntity getOutputAsset() { return outputAsset; }
    public int getAttemptCount() { return attemptCount; }
    public String getLeaseOwner() { return leaseOwner; }
    public UUID getLeaseToken() { return leaseToken; }
    public Instant getLeaseUntil() { return leaseUntil; }
    public Instant getClaimedAt() { return claimedAt; }
    public String getFailureCode() { return failureCode; }
    public String getFailureMessage() { return failureMessage; }
    public Instant getFailedAt() { return failedAt; }
    public UUID getFileId() { return fileId; }
    public UUID getContentRevisionId() { return contentRevisionId; }
    public String getAudioRole() { return audioRole; }
    public String getNormalizedTtsText() { return normalizedTtsText; }
    public String getLanguage() { return language; }
    public String getFingerprint() { return fingerprint; }

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

    private static String sha256(String value, String field) {
        Objects.requireNonNull(value, field);
        if (!value.matches("[0-9a-f]{64}")) {
            throw new IllegalArgumentException(field + " must be lowercase SHA-256");
        }
        return value;
    }
}
