package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.tts.domain.AudioRequirement;
import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioRole;
import java.util.Objects;

public record TtsUtterance(
        ContentAudioRole role,
        AudioRequirement requirement,
        String normalizedText,
        String language,
        String normalizerVersion) {

    public TtsUtterance {
        Objects.requireNonNull(role, "role");
        Objects.requireNonNull(requirement, "requirement");
        normalizedText = required(normalizedText, "normalizedText");
        language = required(language, "language");
        normalizerVersion = required(normalizerVersion, "normalizerVersion");
    }

    private static String required(String value, String field) {
        Objects.requireNonNull(value, field);
        String normalized = value.strip();
        if (normalized.isEmpty()) {
            throw new IllegalArgumentException(field + " must not be blank");
        }
        if (!normalized.equals(value)) {
            throw new IllegalArgumentException(field + " must not contain surrounding whitespace");
        }
        return value;
    }
}
