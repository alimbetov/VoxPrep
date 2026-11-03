package io.github.alimbetov.voxprep.backend.publication.application;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class PublicationPublisherReplayInvariantTest {

    @Test
    void replayFlagDistinguishesExistingReleaseFromNewPublication() {
        PublicationPublishResult fresh = new PublicationPublishResult(
                1L,
                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                java.time.Instant.parse("2026-11-03T09:30:00Z"),
                false);
        PublicationPublishResult replay = new PublicationPublishResult(
                1L,
                fresh.rootSha256(),
                fresh.publishedAt(),
                true);

        assertThat(fresh.replayed()).isFalse();
        assertThat(replay.replayed()).isTrue();
        assertThat(replay.contentVersion()).isEqualTo(fresh.contentVersion());
    }
}
