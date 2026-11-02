package io.github.alimbetov.voxprep.backend.content.persistence;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;

final class ContentEntityRules {

    static final int TITLE_MAX_LENGTH = 256;
    static final int SUBTITLE_MAX_LENGTH = 512;
    static final int DESCRIPTION_MAX_LENGTH = 4096;
    static final int PART_OF_SPEECH_MAX_LENGTH = 128;

    private ContentEntityRules() {
    }

    static String requiredText(String value, String fieldName, int maxLength) {
        Objects.requireNonNull(value, fieldName);
        if (value.isBlank()) {
            throw new IllegalArgumentException(fieldName + " must not be blank");
        }
        if (value.length() > maxLength) {
            throw new IllegalArgumentException(fieldName + " must not exceed " + maxLength + " characters");
        }
        return value;
    }

    static String requiredBodyText(String value, String fieldName) {
        Objects.requireNonNull(value, fieldName);
        if (value.isBlank()) {
            throw new IllegalArgumentException(fieldName + " must not be blank");
        }
        return value;
    }

    static String optionalText(String value, String fieldName, int maxLength) {
        if (value == null) {
            return null;
        }
        return requiredText(value, fieldName, maxLength);
    }

    static int positiveMinutes(int value) {
        if (value < 1) {
            throw new IllegalArgumentException("minutes must be >= 1");
        }
        return value;
    }

    static List<CatalogueCode> uniqueSkillCodes(List<CatalogueCode> values) {
        Objects.requireNonNull(values, "skillCodes");
        var copy = List.copyOf(values);
        if (copy.stream().anyMatch(Objects::isNull)) {
            throw new IllegalArgumentException("skillCodes must not contain null");
        }
        if (new HashSet<>(copy).size() != copy.size()) {
            throw new IllegalArgumentException("skillCodes must not contain duplicates");
        }
        return copy;
    }

    static <T> List<T> nonEmptyList(List<T> values, String fieldName) {
        Objects.requireNonNull(values, fieldName);
        var copy = List.copyOf(values);
        if (copy.isEmpty()) {
            throw new IllegalArgumentException(fieldName + " must not be empty");
        }
        if (copy.stream().anyMatch(Objects::isNull)) {
            throw new IllegalArgumentException(fieldName + " must not contain null");
        }
        return copy;
    }
}
