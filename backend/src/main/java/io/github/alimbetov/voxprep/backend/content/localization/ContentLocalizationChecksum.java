package io.github.alimbetov.voxprep.backend.content.localization;

import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;

/** Server-owned digest over the normalized localization fields, independent of transport. */
public final class ContentLocalizationChecksum {

    private ContentLocalizationChecksum() {
    }

    public static Sha256Digest compute(ContentLocalizationAuthoringService.Fields fields) {
        Objects.requireNonNull(fields, "fields");
        var canonical = String.join("\u001f",
                normalize(fields.title()),
                normalize(fields.subtitle()),
                normalize(fields.description()),
                normalize(fields.translation()),
                normalize(fields.hint()),
                normalize(fields.explanation()));
        try {
            var digest = MessageDigest.getInstance("SHA-256");
            return new Sha256Digest(HexFormat.of().formatHex(
                    digest.digest(canonical.getBytes(StandardCharsets.UTF_8))));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 unavailable", exception);
        }
    }

    private static String normalize(String value) {
        return value == null ? "" : value.trim();
    }
}
