package io.github.alimbetov.voxprep.backend.tts.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

class TtsTextNormalizerTest {

    private final TtsTextNormalizer normalizer = new TtsTextNormalizer();

    @Test
    void normalizesUnicodeLineEndingsWhitespaceAndBlankLinesDeterministically() {
        String input = "  Ｈello\t   world\r\n\r\n\r\nNext   line  ";

        assertThat(normalizer.normalize(input))
                .isEqualTo("Hello world\n\nNext line");
        assertThat(normalizer.normalize(normalizer.normalize(input)))
                .isEqualTo("Hello world\n\nNext line");
    }

    @Test
    void rejectsBlankText() {
        assertThatThrownBy(() -> normalizer.normalize(" \t\r\n "))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("must not be blank");
    }

    @Test
    void exposesStableNormalizerVersion() {
        assertThat(TtsTextNormalizer.VERSION).isEqualTo("tts-text-v1");
    }
}
