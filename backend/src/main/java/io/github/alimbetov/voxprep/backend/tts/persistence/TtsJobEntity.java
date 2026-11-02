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
import java.util.Objects;

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

    protected TtsJobEntity() {
    }

    public TtsJobEntity(TtsVoiceModelEntity voiceModel, String inputText, String inputSha256) {
        this.voiceModel = Objects.requireNonNull(voiceModel, "voiceModel");
        this.inputText = required(inputText, "inputText", 10000);
        this.inputSha256 = sha256(inputSha256);
        this.status = TtsJobStatus.PENDING;
    }

    public TtsVoiceModelEntity getVoiceModel() {
        return voiceModel;
    }

    public String getInputText() {
        return inputText;
    }

    public String getInputSha256() {
        return inputSha256;
    }

    public TtsJobStatus getStatus() {
        return status;
    }

    public FileAssetEntity getOutputAsset() {
        return outputAsset;
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

    private static String sha256(String value) {
        Objects.requireNonNull(value, "inputSha256");
        if (!value.matches("[0-9a-f]{64}")) {
            throw new IllegalArgumentException("inputSha256 must be lowercase SHA-256");
        }
        return value;
    }
}
