package io.github.alimbetov.voxprep.backend.publication.application;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class PublicationPublisherContractTest {

    @Test
    void publishResultCarriesStableLearnerVisibleReleaseFacts() {
        PublicationPublishResult result = new PublicationPublishResult(
                11L,
                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                java.time.Instant.parse("2026-11-03T09:30:00Z"),
                false);

        assertThat(result.contentVersion()).isEqualTo(11L);
        assertThat(result.rootSha256()).hasSize(64);
        assertThat(result.replayed()).isFalse();
    }
}
