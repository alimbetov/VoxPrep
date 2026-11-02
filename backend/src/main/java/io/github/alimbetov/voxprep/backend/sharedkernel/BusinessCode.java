package io.github.alimbetov.voxprep.backend.sharedkernel;

import java.util.Objects;
import java.util.regex.Pattern;

public record BusinessCode(String value) {

    public static final int MAX_LENGTH = 128;
    private static final Pattern PATTERN = Pattern.compile("^[A-Za-z0-9][A-Za-z0-9._-]*$");

    public BusinessCode {
        Objects.requireNonNull(value, "value");
        if (value.length() > MAX_LENGTH) {
            throw new IllegalArgumentException("Business code must not exceed " + MAX_LENGTH + " characters");
        }
        if (!PATTERN.matcher(value).matches()) {
            throw new IllegalArgumentException("Business code must match " + PATTERN.pattern());
        }
    }

    @Override
    public String toString() {
        return value;
    }
}
