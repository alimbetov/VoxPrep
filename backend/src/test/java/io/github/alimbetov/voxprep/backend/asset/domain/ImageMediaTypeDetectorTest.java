package io.github.alimbetov.voxprep.backend.asset.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;

class ImageMediaTypeDetectorTest {

    @Test
    void detectsJpegPngAndWebpFromSignatures() {
        assertThat(ImageMediaTypeDetector.detect(new byte[] {(byte) 0xff, (byte) 0xd8, (byte) 0xff, 0x00}).mediaType())
                .isEqualTo("image/jpeg");
        assertThat(ImageMediaTypeDetector.detect(new byte[] {
                    (byte) 0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00
                }).mediaType())
                .isEqualTo("image/png");

        byte[] webp = "RIFF0000WEBPpayload".getBytes(StandardCharsets.US_ASCII);
        assertThat(ImageMediaTypeDetector.detect(webp).mediaType()).isEqualTo("image/webp");
    }

    @Test
    void rejectsSvgAndHeaderSpoofPayloads() {
        assertThatThrownBy(() -> ImageMediaTypeDetector.detect("<svg></svg>".getBytes(StandardCharsets.UTF_8)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Unsupported");
        assertThatThrownBy(() -> ImageMediaTypeDetector.detect("not-a-jpeg".getBytes(StandardCharsets.UTF_8)))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
