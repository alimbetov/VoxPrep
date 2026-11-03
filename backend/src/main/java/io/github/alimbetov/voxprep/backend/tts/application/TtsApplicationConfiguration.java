package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioPolicy;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class TtsApplicationConfiguration {

    @Bean
    ContentAudioPolicy contentAudioPolicy() {
        return new ContentAudioPolicy();
    }

    @Bean
    TtsTextNormalizer ttsTextNormalizer() {
        return new TtsTextNormalizer();
    }

    @Bean
    ContentTtsPlanner contentTtsPlanner(
            ContentAudioPolicy contentAudioPolicy,
            TtsTextNormalizer ttsTextNormalizer) {
        return new ContentTtsPlanner(contentAudioPolicy, ttsTextNormalizer);
    }
}
