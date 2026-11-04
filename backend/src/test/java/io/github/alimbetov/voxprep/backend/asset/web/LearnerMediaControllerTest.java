package io.github.alimbetov.voxprep.backend.asset.web;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.alimbetov.voxprep.backend.learner.application.LearnerPublishedMediaService;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class LearnerMediaControllerTest {

    private static final String ETAG = "\"abc123\"";

    @Test
    void ifNoneMatchUsesWeakComparisonAndSupportsListsAndWildcard() {
        assertThat(LearnerMediaController.matches(ETAG, ETAG)).isTrue();
        assertThat(LearnerMediaController.matches("W/\"abc123\"", ETAG)).isTrue();
        assertThat(LearnerMediaController.matches("\"other\", W/\"abc123\"", ETAG)).isTrue();
        assertThat(LearnerMediaController.matches("*", ETAG)).isTrue();
    }

    @Test
    void ifNoneMatchRejectsAbsentOrDifferentTags() {
        assertThat(LearnerMediaController.matches(null, ETAG)).isFalse();
        assertThat(LearnerMediaController.matches("", ETAG)).isFalse();
        assertThat(LearnerMediaController.matches("\"different\"", ETAG)).isFalse();
    }

    @Test
    void genericMediaListEtagChangesWithRoleKindOrAssetIdentity() {
        UUID assetId = UUID.randomUUID();
        var audio = new LearnerPublishedMediaService.MediaAssetSnapshot(
                assetId,
                "pronunciation",
                "TTS_AUDIO",
                "audio/mpeg",
                100,
                "a".repeat(64),
                "\"audio\"");
        var image = new LearnerPublishedMediaService.MediaAssetSnapshot(
                assetId,
                "coverImage",
                "COVER_IMAGE",
                "image/webp",
                100,
                "a".repeat(64),
                "\"image\"");

        String audioEtag = LearnerMediaController.mediaListEtag("phrase", "PHRASE", List.of(audio));
        String imageEtag = LearnerMediaController.mediaListEtag("phrase", "PHRASE", List.of(image));

        assertThat(audioEtag).isNotEqualTo(imageEtag);
    }
}
