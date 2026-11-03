package io.github.alimbetov.voxprep.backend.asset.domain;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

class MediaAssetPolicyTest {

    @Test
    void acceptsSupportedCoverAndContentImagesWithinLimits() {
        assertThatCode(() -> MediaAssetPolicy.validate(
                        FileAssetKind.COVER_IMAGE, "image/jpeg", MediaAssetPolicy.COVER_IMAGE_MAX_BYTES))
                .doesNotThrowAnyException();
        assertThatCode(() -> MediaAssetPolicy.validate(
                        FileAssetKind.CONTENT_IMAGE, "image/webp", MediaAssetPolicy.CONTENT_IMAGE_MAX_BYTES))
                .doesNotThrowAnyException();
    }

    @Test
    void rejectsActiveOrUnsupportedImageTypes() {
        assertThatThrownBy(() -> MediaAssetPolicy.validate(FileAssetKind.COVER_IMAGE, "image/svg+xml", 1024))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Unsupported image media type");
    }

    @Test
    void enforcesKindSpecificSizeCaps() {
        assertThatThrownBy(() -> MediaAssetPolicy.validate(
                        FileAssetKind.COVER_IMAGE,
                        "image/png",
                        MediaAssetPolicy.COVER_IMAGE_MAX_BYTES + 1))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("COVER_IMAGE");
        assertThatThrownBy(() -> MediaAssetPolicy.validate(
                        FileAssetKind.CONTENT_IMAGE,
                        "image/png",
                        MediaAssetPolicy.CONTENT_IMAGE_MAX_BYTES + 1))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("CONTENT_IMAGE");
    }

    @Test
    void leavesNonImageAssetKindsToTheirOwningDomain() {
        assertThatCode(() -> MediaAssetPolicy.validate(FileAssetKind.TTS_AUDIO, "audio/mpeg", 50_000_000))
                .doesNotThrowAnyException();
    }
}
