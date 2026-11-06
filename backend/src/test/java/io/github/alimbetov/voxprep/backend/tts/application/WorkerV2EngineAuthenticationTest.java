package io.github.alimbetov.voxprep.backend.tts.application;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import org.junit.jupiter.api.Test;

class WorkerV2EngineAuthenticationTest {

    private static WorkerApiKeyVerifier verifier(String piper, String kokoro) {
        WorkerDeliveryProperties config = new WorkerDeliveryProperties();
        config.setApiKey(piper);
        config.setKokoroApiKey(kokoro);
        return new WorkerApiKeyVerifier(config);
    }

    @Test
    void legacyCredentialRemainsPiperOnly() {
        var verifier = verifier("piper-private-test-token", "kokoro-private-test-token");
        assertThat(verifier.authenticatedEngine("Bearer piper-private-test-token"))
                .contains(TtsEngine.PIPER);
        assertThat(verifier.authorized("Bearer piper-private-test-token")).isTrue();
        assertThat(verifier.authorized("Bearer kokoro-private-test-token")).isFalse();
    }

    @Test
    void separateCredentialResolvesToKokoroOnly() {
        var verifier = verifier("piper-private-test-token", "kokoro-private-test-token");
        assertThat(verifier.authenticatedEngine("Bearer kokoro-private-test-token"))
                .contains(TtsEngine.KOKORO);
        assertThat(verifier.authenticatedEngine("Bearer invalid-token")).isEmpty();
        assertThat(verifier.authenticatedEngine(null)).isEmpty();
    }

    @Test
    void absentKokoroCredentialFailsClosed() {
        var verifier = verifier("piper-private-test-token", "");
        assertThat(verifier.authenticatedEngine("Bearer kokoro-private-test-token")).isEmpty();
        assertThat(verifier.authenticatedEngine("Bearer piper-private-test-token"))
                .contains(TtsEngine.PIPER);
    }

    @Test
    void accidentallySharedSecretFailsClosedForV2() {
        var verifier = verifier("same-token", "same-token");
        assertThat(verifier.authenticatedEngine("Bearer same-token")).isEmpty();
    }
}
