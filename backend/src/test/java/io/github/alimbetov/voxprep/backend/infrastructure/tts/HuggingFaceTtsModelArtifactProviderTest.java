package io.github.alimbetov.voxprep.backend.infrastructure.tts;

import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.tts.application.TtsModelArtifactSource;
import org.junit.jupiter.api.Test;

class HuggingFaceTtsModelArtifactProviderTest {

    @Test
    void rejectsNonHuggingFaceHostBeforeNetworkCall() {
        HuggingFaceTtsModelArtifactProvider provider = new HuggingFaceTtsModelArtifactProvider();
        var request = new TtsModelArtifactSource.ArtifactRequest(
                "huggingface",
                "rhasspy/piper-voices",
                "rev-1",
                "https://example.com/rhasspy/piper-voices/resolve/rev-1/model.onnx");

        assertThatThrownBy(() -> provider.fetch(request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Unsupported Hugging Face artifact URL");
    }

    @Test
    void rejectsUrlThatDoesNotMatchPinnedRepositoryRevision() {
        HuggingFaceTtsModelArtifactProvider provider = new HuggingFaceTtsModelArtifactProvider();
        var request = new TtsModelArtifactSource.ArtifactRequest(
                "huggingface",
                "rhasspy/piper-voices",
                "rev-1",
                "https://huggingface.co/rhasspy/piper-voices/resolve/main/model.onnx");

        assertThatThrownBy(() -> provider.fetch(request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("pinned repository/revision");
    }
}
