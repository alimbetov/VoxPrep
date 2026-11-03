package io.github.alimbetov.voxprep.backend.catalogue.domain;

import java.util.Objects;
import java.util.regex.Pattern;

public record CatalogueCode(String value) {

    public static final int MAX_LENGTH = CatalogueConstraints.CODE_MAX_LENGTH;
    public static final String REGEXP = CatalogueConstraints.CODE_PATTERN;
    private static final Pattern PATTERN = Pattern.compile(REGEXP);

    public CatalogueCode {
        Objects.requireNonNull(value, "value");
        if (value.length() > MAX_LENGTH) {
            throw new IllegalArgumentException("Catalogue code must not exceed " + MAX_LENGTH + " characters");
        }
        if (!PATTERN.matcher(value).matches()) {
            throw new IllegalArgumentException(
                    "Catalogue code must match " + REGEXP + " without normalization");
        }
    }

    @Override
    public String toString() {
        return value;
    }
}
