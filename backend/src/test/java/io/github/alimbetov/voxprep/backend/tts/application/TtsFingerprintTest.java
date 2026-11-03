package io.github.alimbetov.voxprep.backend.tts.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.tts.domain.AudioRequirement;
import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioRole;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelEntity;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class TtsFingerprintTest {

    @Test
    void isDeterministicAndIncludesNormalizerVersionLanguageAndModelIdentity() {
        TtsVoiceModelEntity model = model("en_US.lessac.high", "1.2.0", "model-v1", 'a', 'b');
        TtsUtterance utterance = new TtsUtterance(
                ContentAudioRole.PRONUNCIATION,
                AudioRequirement.RECOMMENDED,
                "Hello world",
                "en-US",
                TtsTextNormalizer.VERSION);
        UUID revisionId = UUID.fromString("11111111-1111-1111-1111-111111111111");
        String checksum = "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc";

        String first = TtsFingerprint.compute(
                revisionId, checksum, utterance, model, TtsOutputFinalizationService.AUDIO_PROFILE);
        String second = TtsFingerprint.compute(
                revisionId, checksum, utterance, model, TtsOutputFinalizationService.AUDIO_PROFILE);
        String changedLanguage = TtsFingerprint.compute(
                revisionId,
                checksum,
                new TtsUtterance(
                        ContentAudioRole.PRONUNCIATION,
                        AudioRequirement.RECOMMENDED,
                        "Hello world",
                        "en-GB",
                        TtsTextNormalizer.VERSION),
                model,
                TtsOutputFinalizationService.AUDIO_PROFILE);
        String changedNormalizer = TtsFingerprint.compute(
                revisionId,
                checksum,
                new TtsUtterance(
                        ContentAudioRole.PRONUNCIATION,
                        AudioRequirement.RECOMMENDED,
                        "Hello world",
                        "en-US",
                        "tts-text-v2"),
                model,
                TtsOutputFinalizationService.AUDIO_PROFILE);
        TtsVoiceModelEntity changedModel = model("en_US.lessac.high", "1.2.0", "model-v2", 'd', 'e');
        String changedModelFingerprint = TtsFingerprint.compute(
                revisionId, checksum, utterance, changedModel, TtsOutputFinalizationService.AUDIO_PROFILE);

        assertThat(first).matches("[0-9a-f]{64}").isEqualTo(second);
        assertThat(changedLanguage).isNotEqualTo(first);
        assertThat(changedNormalizer).isNotEqualTo(first);
        assertThat(changedModelFingerprint).isNotEqualTo(first);
        assertThat(TtsFingerprint.VERSION).isEqualTo("tts-fingerprint-v1");
    }

    private static TtsVoiceModelEntity model(
            String code,
            String engineVersion,
            String modelVersion,
            char modelHash,
            char configHash) {
        TtsVoiceModelEntity model = mock(TtsVoiceModelEntity.class);
        when(model.getCode()).thenReturn(code);
        when(model.getEngineVersion()).thenReturn(engineVersion);
        when(model.getModelVersion()).thenReturn(modelVersion);
        when(model.getModelSha256()).thenReturn(String.valueOf(modelHash).repeat(64));
        when(model.getConfigSha256()).thenReturn(String.valueOf(configHash).repeat(64));
        return model;
    }
}
