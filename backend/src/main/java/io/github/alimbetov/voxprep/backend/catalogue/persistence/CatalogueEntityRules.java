package io.github.alimbetov.voxprep.backend.catalogue.persistence;

import java.util.Objects;

final class CatalogueEntityRules {

    static final int TITLE_MAX_LENGTH = 256;
    static final int DESCRIPTION_MAX_LENGTH = 4096;
    static final int EXTERNAL_ID_MAX_LENGTH = 256;

    private CatalogueEntityRules() {
    }

    static String requiredText(String value, String fieldName, int maxLength) {
        Objects.requireNonNull(value, fieldName);
        if (value.isBlank()) {
            throw new IllegalArgumentException(fieldName + " must not be blank");
        }
        if (!value.equals(value.strip())) {
            throw new IllegalArgumentException(fieldName + " must not contain leading or trailing whitespace");
        }
        if (value.length() > maxLength) {
            throw new IllegalArgumentException(fieldName + " must not exceed " + maxLength + " characters");
        }
        return value;
    }

    static int sortOrder(int value) {
        if (value < 0) {
            throw new IllegalArgumentException("sortOrder must not be negative");
        }
        return value;
    }
}
