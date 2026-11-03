package io.github.alimbetov.voxprep.backend.tts.application;

import java.util.Locale;
import java.util.Objects;

public record TtsModelSelector(String locale, String voice, String quality) {

    public TtsModelSelector {
        locale = required(locale, "locale").replace('-', '_');
        voice = required(voice, "voice").toLowerCase(Locale.ROOT);
        quality = required(quality, "quality").toLowerCase(Locale.ROOT);
    }

    public String modelCode() {
        return locale + "." + voice + "." + quality;
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
        return normalized;
    }
}
