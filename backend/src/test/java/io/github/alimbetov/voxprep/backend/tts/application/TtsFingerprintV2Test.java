package io.github.alimbetov.voxprep.backend.tts.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.tts.domain.AudioRequirement;
import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioRole;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class TtsFingerprintV2Test {
    private static final UUID REVISION = UUID.fromString("11111111-1111-1111-1111-111111111111");

    private static TtsArtifactManifest manifest(String voiceHash) {
        return new TtsArtifactManifest(TtsEngine.KOKORO, "pinned-revision", List.of(
                new TtsArtifactManifest.Artifact("model.onnx", "MODEL",
                        "a".repeat(64), 123, "application/octet-stream"),
                new TtsArtifactManifest.Artifact("voices/af_heart.bin", "VOICE",
                        voiceHash, 100, "application/octet-stream")));
    }

    private static String fingerprint(TtsArtifactManifest model, Map<String, String> parameters) {
        return TtsFingerprint.computeV2(REVISION, "c".repeat(64),
                new TtsUtterance(ContentAudioRole.PRONUNCIATION, AudioRequirement.RECOMMENDED,
                        "Hello world", "en-US", TtsTextNormalizer.VERSION),
                TtsEngine.KOKORO, "kokoro-onnx-pinned", model,
                "af_heart", model.artifacts().get(1).sha256(),
                "phonemizer-pinned", parameters, TtsOutputFinalizationService.AUDIO_PROFILE);
    }

    @Test
    void canonicalV2IsIndependentOfParameterInsertionOrder() {
        var model = manifest("b".repeat(64));
        String first = fingerprint(model, Map.of("speed", "1", "language", "en-US"));
        String second = fingerprint(model, Map.of("language", "en-US", "speed", "1"));
        assertThat(first).matches("[0-9a-f]{64}").isEqualTo(second);
        assertThat(TtsFingerprint.VERSION).isEqualTo("tts-fingerprint-v1");
        assertThat(TtsFingerprint.VERSION_V2).isEqualTo("tts-fingerprint-v2");
    }

    @Test
    void modelVoiceAndSettingsArePartOfV2Identity() {
        var model = manifest("b".repeat(64));
        String original = fingerprint(model, Map.of("speed", "1"));
        assertThat(fingerprint(manifest("d".repeat(64)), Map.of("speed", "1")))
                .isNotEqualTo(original);
        assertThat(fingerprint(model, Map.of("speed", "1.1"))).isNotEqualTo(original);
    }

    @Test
    void wrongEngineFailsClosed() {
        assertThatThrownBy(() -> TtsFingerprint.computeV2(REVISION, "c".repeat(64),
                new TtsUtterance(ContentAudioRole.PRONUNCIATION, AudioRequirement.RECOMMENDED,
                        "Hello world", "en-US", TtsTextNormalizer.VERSION),
                TtsEngine.PIPER, "runtime", manifest("b".repeat(64)),
                "af_heart", "b".repeat(64), "phonemizer", Map.of(), "mp3-mono-24k-64k-v1"))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
