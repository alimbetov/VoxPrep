package io.github.alimbetov.voxprep.backend.tts.persistence;

import io.github.alimbetov.voxprep.backend.infrastructure.persistence.AbstractJpaEntity;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsVoiceModelStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

@Entity
@Table(
        name = "tts_voice_model",
        schema = "app",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_tts_voice_model__code", columnNames = "code"),
                @UniqueConstraint(name = "uk_tts_voice_model__id_voice", columnNames = {"id", "voice_id"})
        })
public class TtsVoiceModelEntity extends AbstractJpaEntity {

    @Column(name = "code", nullable = false, updatable = false, length = 128)
    private String code;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "voice_id", nullable = false, updatable = false)
    private TtsVoiceEntity voice;

    @Enumerated(EnumType.STRING)
    @Column(name = "engine", nullable = false, updatable = false, length = 32)
    private TtsEngine engine;

    @Column(name = "engine_version", nullable = false, updatable = false, length = 64)
    private String engineVersion;

    @Column(name = "model_version", nullable = false, updatable = false, length = 128)
    private String modelVersion;

    @Column(name = "model_asset_id", updatable = false)
    private UUID modelAssetId;

    @Column(name = "config_asset_id", updatable = false)
    private UUID configAssetId;

    @Column(name = "model_sha256", updatable = false, length = 64)
    private String modelSha256;

    @Column(name = "config_sha256", updatable = false, length = 64)
    private String configSha256;

    @Column(name = "source_provider", updatable = false, length = 64)
    private String sourceProvider;

    @Column(name = "source_repository", updatable = false, length = 256)
    private String sourceRepository;

    @Column(name = "source_revision", updatable = false, length = 128)
    private String sourceRevision;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 32)
    private TtsVoiceModelStatus status;

    @Column(name = "license_name", length = 256)
    private String licenseName;

    @Column(name = "license_reference", length = 1024)
    private String licenseReference;

    @Column(name = "commercial_use_reviewed", nullable = false)
    private boolean commercialUseReviewed;

    @Column(name = "approved_at")
    private Instant approvedAt;

    protected TtsVoiceModelEntity() {
    }

    public TtsVoiceModelEntity(
            String code,
            TtsVoiceEntity voice,
            TtsEngine engine,
            String engineVersion,
            String modelVersion,
            UUID modelAssetId,
            UUID configAssetId,
            String modelSha256,
            String configSha256,
            TtsVoiceModelStatus status,
            String licenseName,
            String licenseReference,
            boolean commercialUseReviewed,
            Instant approvedAt) {
        this(
                code,
                voice,
                engine,
                engineVersion,
                modelVersion,
                modelAssetId,
                configAssetId,
                modelSha256,
                configSha256,
                null,
                null,
                null,
                status,
                licenseName,
                licenseReference,
                commercialUseReviewed,
                approvedAt);
    }

    public TtsVoiceModelEntity(
            String code,
            TtsVoiceEntity voice,
            TtsEngine engine,
            String engineVersion,
            String modelVersion,
            UUID modelAssetId,
            UUID configAssetId,
            String modelSha256,
            String configSha256,
            String sourceProvider,
            String sourceRepository,
            String sourceRevision,
            TtsVoiceModelStatus status,
            String licenseName,
            String licenseReference,
            boolean commercialUseReviewed,
            Instant approvedAt) {
        this.code = TtsVoiceEntity.required(code, "code", 128);
        this.voice = Objects.requireNonNull(voice, "voice");
        this.engine = Objects.requireNonNull(engine, "engine");
        this.engineVersion = TtsVoiceEntity.required(engineVersion, "engineVersion", 64);
        this.modelVersion = TtsVoiceEntity.required(modelVersion, "modelVersion", 128);
        if (engine == TtsEngine.PIPER) {
            this.modelAssetId = Objects.requireNonNull(modelAssetId, "modelAssetId");
            this.configAssetId = Objects.requireNonNull(configAssetId, "configAssetId");
            this.modelSha256 = sha256(modelSha256, "modelSha256");
            this.configSha256 = sha256(configSha256, "configSha256");
        } else if (engine == TtsEngine.KOKORO) {
            if (modelAssetId != null || configAssetId != null
                    || modelSha256 != null || configSha256 != null) {
                throw new IllegalArgumentException("Kokoro uses an immutable bundle, not Piper assets");
            }
        } else {
            throw new IllegalArgumentException("Unsupported TTS engine");
        }
        this.sourceProvider = TtsVoiceEntity.optional(sourceProvider, "sourceProvider", 64);
        this.sourceRepository = TtsVoiceEntity.optional(sourceRepository, "sourceRepository", 256);
        this.sourceRevision = TtsVoiceEntity.optional(sourceRevision, "sourceRevision", 128);
        updateReviewMetadata(status, licenseName, licenseReference, commercialUseReviewed, approvedAt);
    }

    /**
     * Kokoro is registered in the shared voice-model catalog with NO Piper
     * model/config assets. Binding to a verified multi-asset bundle is a
     * separate immutable operation and must precede job enrollment.
     */
    public static TtsVoiceModelEntity forKokoro(
            String code, TtsVoiceEntity voice, String engineVersion,
            String modelVersion, String sourceRepository, String sourceRevision,
            TtsVoiceModelStatus status, String licenseName,
            String licenseReference, boolean commercialUseReviewed,
            Instant approvedAt) {
        return new TtsVoiceModelEntity(
                code, voice, TtsEngine.KOKORO, engineVersion, modelVersion,
                null, null, null, null, "huggingface",
                sourceRepository, sourceRevision, status,
                licenseName, licenseReference, commercialUseReviewed, approvedAt);
    }

    public void updateReviewMetadata(
            TtsVoiceModelStatus status,
            String licenseName,
            String licenseReference,
            boolean commercialUseReviewed,
            Instant approvedAt) {
        TtsVoiceModelStatus requiredStatus = Objects.requireNonNull(status, "status");
        String normalizedLicenseName = TtsVoiceEntity.optional(licenseName, "licenseName", 256);
        String normalizedLicenseReference = TtsVoiceEntity.optional(licenseReference, "licenseReference", 1024);
        if (requiresApprovalTimestamp(requiredStatus) && approvedAt == null) {
            throw new IllegalArgumentException("approvedAt is required for approved/active/deprecated model");
        }
        validateActivationPolicy(
                requiredStatus,
                normalizedLicenseName,
                normalizedLicenseReference,
                commercialUseReviewed,
                approvedAt);
        this.status = requiredStatus;
        this.licenseName = normalizedLicenseName;
        this.licenseReference = normalizedLicenseReference;
        this.commercialUseReviewed = commercialUseReviewed;
        this.approvedAt = approvedAt;
    }

    public boolean selectableForNewJobs() {
        return status == TtsVoiceModelStatus.ACTIVE && voice.isEnabled();
    }

    public String getCode() { return code; }
    public TtsVoiceEntity getVoice() { return voice; }
    public TtsEngine getEngine() { return engine; }
    public String getEngineVersion() { return engineVersion; }
    public String getModelVersion() { return modelVersion; }
    public UUID getModelAssetId() { return modelAssetId; }
    public UUID getConfigAssetId() { return configAssetId; }
    public String getModelSha256() { return modelSha256; }
    public String getConfigSha256() { return configSha256; }
    public String getSourceProvider() { return sourceProvider; }
    public String getSourceRepository() { return sourceRepository; }
    public String getSourceRevision() { return sourceRevision; }
    public TtsVoiceModelStatus getStatus() { return status; }
    public String getLicenseName() { return licenseName; }
    public String getLicenseReference() { return licenseReference; }
    public boolean isCommercialUseReviewed() { return commercialUseReviewed; }
    public Instant getApprovedAt() { return approvedAt; }

    private void validateActivationPolicy(
            TtsVoiceModelStatus status,
            String licenseName,
            String licenseReference,
            boolean commercialUseReviewed,
            Instant approvedAt) {
        if (status != TtsVoiceModelStatus.ACTIVE) {
            return;
        }
        if (sourceProvider == null || sourceRepository == null || sourceRevision == null) {
            throw new IllegalArgumentException("ACTIVE TTS model requires pinned source provenance");
        }
        if (licenseName == null || licenseReference == null) {
            throw new IllegalArgumentException("ACTIVE TTS model requires license metadata");
        }
        if (!commercialUseReviewed) {
            throw new IllegalArgumentException("ACTIVE TTS model requires commercial-use review");
        }
        if (approvedAt == null) {
            throw new IllegalArgumentException("ACTIVE TTS model requires approvedAt");
        }
    }

    private static boolean requiresApprovalTimestamp(TtsVoiceModelStatus status) {
        return status == TtsVoiceModelStatus.APPROVED
                || status == TtsVoiceModelStatus.ACTIVE
                || status == TtsVoiceModelStatus.DEPRECATED;
    }

    private static String sha256(String value, String field) {
        Objects.requireNonNull(value, field);
        if (!value.matches("[0-9a-f]{64}")) {
            throw new IllegalArgumentException(field + " must be lowercase SHA-256");
        }
        return value;
    }
}
