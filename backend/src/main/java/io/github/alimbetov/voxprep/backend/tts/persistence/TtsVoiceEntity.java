package io.github.alimbetov.voxprep.backend.tts.persistence;

import io.github.alimbetov.voxprep.backend.infrastructure.persistence.AbstractJpaEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.util.Objects;

@Entity
@Table(
        name = "tts_voice",
        schema = "app",
        uniqueConstraints = @UniqueConstraint(name = "uk_tts_voice__code", columnNames = "code"))
public class TtsVoiceEntity extends AbstractJpaEntity {

    @Column(name = "code", nullable = false, updatable = false, length = 128)
    private String code;

    @Column(name = "display_name", nullable = false, length = 256)
    private String displayName;

    @Column(name = "language", nullable = false, length = 64)
    private String language;

    @Column(name = "accent", length = 128)
    private String accent;

    @Column(name = "gender", length = 64)
    private String gender;

    @Column(name = "style", length = 128)
    private String style;

    @Column(name = "enabled", nullable = false)
    private boolean enabled;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "default_model_id")
    private TtsVoiceModelEntity defaultModel;

    protected TtsVoiceEntity() {
    }

    public TtsVoiceEntity(
            String code,
            String displayName,
            String language,
            String accent,
            String gender,
            String style,
            boolean enabled) {
        this.code = required(code, "code", 128);
        updateMetadata(displayName, language, accent, gender, style, enabled);
    }

    public void updateMetadata(
            String displayName,
            String language,
            String accent,
            String gender,
            String style,
            boolean enabled) {
        this.displayName = required(displayName, "displayName", 256);
        this.language = required(language, "language", 64);
        this.accent = optional(accent, "accent", 128);
        this.gender = optional(gender, "gender", 64);
        this.style = optional(style, "style", 128);
        this.enabled = enabled;
    }

    public void selectDefaultModel(TtsVoiceModelEntity model) {
        Objects.requireNonNull(model, "model");
        if (model.getVoice() != this) {
            throw new IllegalArgumentException("Default TTS model must belong to this voice");
        }
        this.defaultModel = model;
    }

    public String getCode() {
        return code;
    }

    public String getDisplayName() {
        return displayName;
    }

    public String getLanguage() {
        return language;
    }

    public String getAccent() {
        return accent;
    }

    public String getGender() {
        return gender;
    }

    public String getStyle() {
        return style;
    }

    public boolean isEnabled() {
        return enabled;
    }

    public TtsVoiceModelEntity getDefaultModel() {
        return defaultModel;
    }

    static String required(String value, String field, int maxLength) {
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

    static String optional(String value, String field, int maxLength) {
        return value == null ? null : required(value, field, maxLength);
    }
}
