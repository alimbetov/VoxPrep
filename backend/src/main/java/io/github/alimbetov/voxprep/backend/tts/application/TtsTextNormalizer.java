package io.github.alimbetov.voxprep.backend.tts.application;

import java.text.Normalizer;
import java.util.Objects;

public final class TtsTextNormalizer {

    public static final String VERSION = "tts-text-v1";

    public String normalize(String value) {
        Objects.requireNonNull(value, "value");

        String normalized = Normalizer.normalize(value, Normalizer.Form.NFKC)
                .replace("\r\n", "\n")
                .replace('\r', '\n')
                .strip();

        if (normalized.isEmpty()) {
            throw new IllegalArgumentException("TTS text must not be blank");
        }

        StringBuilder result = new StringBuilder(normalized.length());
        int consecutiveNewlines = 0;
        boolean horizontalWhitespace = false;

        for (int index = 0; index < normalized.length(); index++) {
            char current = normalized.charAt(index);
            if (current == '\n') {
                trimTrailingSpace(result);
                consecutiveNewlines++;
                horizontalWhitespace = false;
                continue;
            }
            if (current == ' ' || current == '\t' || current == '\f') {
                horizontalWhitespace = true;
                continue;
            }

            if (consecutiveNewlines > 0) {
                int newlineCount = Math.min(consecutiveNewlines, 2);
                for (int count = 0; count < newlineCount; count++) {
                    result.append('\n');
                }
                consecutiveNewlines = 0;
                horizontalWhitespace = false;
            } else if (horizontalWhitespace && result.length() > 0 && result.charAt(result.length() - 1) != '\n') {
                result.append(' ');
            }

            result.append(current);
            horizontalWhitespace = false;
        }

        trimTrailingSpace(result);
        while (result.length() > 0 && result.charAt(result.length() - 1) == '\n') {
            result.deleteCharAt(result.length() - 1);
        }

        if (result.length() == 0) {
            throw new IllegalArgumentException("TTS text must not be blank");
        }
        return result.toString();
    }

    private static void trimTrailingSpace(StringBuilder value) {
        while (value.length() > 0 && value.charAt(value.length() - 1) == ' ') {
            value.deleteCharAt(value.length() - 1);
        }
    }
}
