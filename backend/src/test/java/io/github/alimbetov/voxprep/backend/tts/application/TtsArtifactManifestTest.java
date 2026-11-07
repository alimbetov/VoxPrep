package io.github.alimbetov.voxprep.backend.tts.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import java.util.List;
import org.junit.jupiter.api.Test;

class TtsArtifactManifestTest {
    private static final String MODEL_SHA = "a".repeat(64);
    private static final String VOICE_SHA = "b".repeat(64);

    @Test
    void canonicalHashIgnoresSuppliedArtifactOrder() {
        var model = new TtsArtifactManifest.Artifact(
                "model.onnx", "MODEL", MODEL_SHA, 1234, "application/octet-stream");
        var voice = new TtsArtifactManifest.Artifact(
                "voices/af_heart.bin", "VOICE", VOICE_SHA, 321, "application/octet-stream");
        var first = new TtsArtifactManifest(TtsEngine.KOKORO, "pinned-commit", List.of(model, voice));
        var reversed = new TtsArtifactManifest(TtsEngine.KOKORO, "pinned-commit", List.of(voice, model));
        assertThat(first.sha256()).isEqualTo(reversed.sha256()).hasSize(64);
    }

    @Test
    void changedVoiceBytesChangeIdentity() {
        var model = new TtsArtifactManifest.Artifact(
                "model.onnx", "MODEL", MODEL_SHA, 1234, "application/octet-stream");
        var firstVoice = new TtsArtifactManifest.Artifact(
                "voices/af_heart.bin", "VOICE", VOICE_SHA, 321, "application/octet-stream");
        var changedVoice = new TtsArtifactManifest.Artifact(
                "voices/af_heart.bin", "VOICE", "c".repeat(64), 321, "application/octet-stream");
        assertThat(new TtsArtifactManifest(TtsEngine.KOKORO, "commit1", List.of(model, firstVoice)).sha256())
                .isNotEqualTo(new TtsArtifactManifest(TtsEngine.KOKORO, "commit1", List.of(model, changedVoice)).sha256());
    }

    @Test
    void duplicateAndUnsafePathsFailClosed() {
        var artifact = new TtsArtifactManifest.Artifact(
                "model.onnx", "MODEL", MODEL_SHA, 1234, "application/octet-stream");
        assertThatThrownBy(() -> new TtsArtifactManifest(TtsEngine.KOKORO, "rev", List.of(artifact, artifact)))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new TtsArtifactManifest.Artifact(
                "../model.onnx", "MODEL", MODEL_SHA, 10, "application/octet-stream"))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new TtsArtifactManifest.Artifact(
                "/etc/passwd", "MODEL", MODEL_SHA, 10, "application/octet-stream"))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
