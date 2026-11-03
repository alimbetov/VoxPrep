package io.github.alimbetov.voxprep.backend.tts.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import org.junit.jupiter.api.Test;

class RoutingTtsModelArtifactSourceTest {

    @Test
    void routesByNormalizedProviderId() {
        TtsModelArtifactProvider provider = mock(TtsModelArtifactProvider.class);
        when(provider.providerId()).thenReturn("HuggingFace");
        TtsModelArtifactSource.ArtifactRequest request = new TtsModelArtifactSource.ArtifactRequest(
                "huggingface", "rhasspy/piper-voices", "rev-1", "https://huggingface.co/example");
        when(provider.fetch(request)).thenReturn(new byte[] {1, 2, 3});

        RoutingTtsModelArtifactSource source = new RoutingTtsModelArtifactSource(List.of(provider));

        assertThat(source.fetch(request)).containsExactly(1, 2, 3);
        verify(provider).fetch(request);
    }

    @Test
    void failsClosedForUnknownProvider() {
        RoutingTtsModelArtifactSource source = new RoutingTtsModelArtifactSource(List.of());
        TtsModelArtifactSource.ArtifactRequest request = new TtsModelArtifactSource.ArtifactRequest(
                "unknown", "repo", "rev", "https://example.invalid/artifact");

        assertThatThrownBy(() -> source.fetch(request))
                .isInstanceOf(RoutingTtsModelArtifactSource.UnsupportedTtsArtifactProviderException.class);
    }

    @Test
    void rejectsDuplicateProviderIdsIgnoringCase() {
        TtsModelArtifactProvider first = mock(TtsModelArtifactProvider.class);
        TtsModelArtifactProvider second = mock(TtsModelArtifactProvider.class);
        when(first.providerId()).thenReturn("HUGGINGFACE");
        when(second.providerId()).thenReturn("huggingface");

        assertThatThrownBy(() -> new RoutingTtsModelArtifactSource(List.of(first, second)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Duplicate TTS artifact provider");
    }
}
