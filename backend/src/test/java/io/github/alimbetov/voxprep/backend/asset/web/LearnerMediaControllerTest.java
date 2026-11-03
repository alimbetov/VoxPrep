package io.github.alimbetov.voxprep.backend.asset.web;

import static org.assertj.core.api.Assertions.assertThat;

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
}
