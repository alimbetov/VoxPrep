package io.github.alimbetov.voxprep.backend.sharedkernel;

import java.util.Objects;

public record StableCode(String value) {

    public static final int MAX_LENGTH = 128;

    public StableCode {
        Objects.requireNonNull(value, "value");
        if (value.isBlank()) {
            throw new IllegalArgumentException("Stable code must not be blank");
        }
        if (value.length() > MAX_LENGTH) {
            throw new IllegalArgumentException("Stable code must not exceed " + MAX_LENGTH + " characters");
        }
        if (!value.equals(value.strip())) {
            throw new IllegalArgumentException("Stable code must not contain leading or trailing whitespace");
        }
        if (value.codePoints().anyMatch(Character::isISOControl)) {
            throw new IllegalArgumentException("Stable code must not contain control characters");
        }
    }

    @Override
    public String toString() {
        return value;
    }
}
