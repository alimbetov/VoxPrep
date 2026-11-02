package io.github.alimbetov.voxprep.backend.sharedkernel;

import java.util.Objects;
import java.util.regex.Pattern;

public record Sha256Digest(String value) {

    public static final int LENGTH = 64;
    private static final Pattern PATTERN = Pattern.compile("^[0-9a-f]{64}$");

    public Sha256Digest {
        Objects.requireNonNull(value, "value");
        if (!PATTERN.matcher(value).matches()) {
            throw new IllegalArgumentException("SHA-256 digest must be exactly 64 lowercase hexadecimal characters");
        }
    }

    @Override
    public String toString() {
        return value;
    }
}
