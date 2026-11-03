package io.github.alimbetov.voxprep.backend.catalogue.persistence;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueConstraints;
import java.util.Objects;

final class CatalogueEntityRules {

    static final int TITLE_MAX_LENGTH = CatalogueConstraints.TITLE_MAX_LENGTH;
    static final int DESCRIPTION_MAX_LENGTH = CatalogueConstraints.DESCRIPTION_MAX_LENGTH;
    static final int EXTERNAL_ID_MAX_LENGTH = CatalogueConstraints.EXTERNAL_ID_MAX_LENGTH;

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
