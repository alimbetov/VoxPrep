package io.github.alimbetov.voxprep.backend.tts.web;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import io.github.alimbetov.voxprep.backend.tts.application.WorkerDeliveryProperties;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsVoiceModelStatus;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelRepository;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceRepository;
import io.github.alimbetov.voxprep.backend.tts.support.TtsTestAssets;
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

@ActiveProfiles("test")
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class TtsModelDeliveryIntegrationTest {

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private WorkerDeliveryProperties workerProperties;
    @Autowired
    private FileAssetRepository assetRepository;
    @Autowired
    private TtsVoiceRepository voiceRepository;
    @Autowired
    private TtsVoiceModelRepository modelRepository;

    @Test
    void workerMustAuthenticateBeforeModelLookup() throws Exception {
        mockMvc.perform(get("/internal/tts/models/{id}", java.util.UUID.randomUUID()))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void returnsExactActiveModelAndConfigWithPresignedUrls() throws Exception {
        var voice = voiceRepository.saveAndFlush(new TtsVoiceEntity(
                "voice-delivery", "US English Lessac", "en-US", "US", "FEMALE", "NEUTRAL", true));
        var assets = TtsTestAssets.createModelAssets(assetRepository, "delivery", 'a', 'b');
        var model = modelRepository.saveAndFlush(new TtsVoiceModelEntity(
                "model-delivery",
                voice,
                TtsEngine.PIPER,
                "1.3.0",
                "en_US-lessac-medium-v1",
                assets.modelAssetId(),
                assets.configAssetId(),
                String.valueOf('a').repeat(64),
                String.valueOf('b').repeat(64),
                TtsVoiceModelStatus.ACTIVE,
                "MIT",
                "https://example.invalid/license",
                true,
                Instant.parse("2026-11-02T18:00:00Z")));

        mockMvc.perform(get("/internal/tts/models/{id}", model.getId())
                        .header(TtsModelDeliveryController.WORKER_KEY_HEADER, workerProperties.getApiKey()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.voiceModelId").value(model.getId().toString()))
                .andExpect(jsonPath("$.engine").value("PIPER"))
                .andExpect(jsonPath("$.engineVersion").value("1.3.0"))
                .andExpect(jsonPath("$.model.assetId").value(assets.modelAssetId().toString()))
                .andExpect(jsonPath("$.model.sha256").value(String.valueOf('a').repeat(64)))
                .andExpect(jsonPath("$.model.downloadUrl").value(org.hamcrest.Matchers.containsString("X-Amz-Signature")))
                .andExpect(jsonPath("$.config.assetId").value(assets.configAssetId().toString()))
                .andExpect(jsonPath("$.config.sha256").value(String.valueOf('b').repeat(64)))
                .andExpect(jsonPath("$.config.downloadUrl").value(org.hamcrest.Matchers.containsString("X-Amz-Signature")));
    }

    @Test
    void databaseRejectsWrongAssetKindForActiveModel() {
        var voice = voiceRepository.saveAndFlush(new TtsVoiceEntity(
                "voice-wrong-kind", "US English Lessac", "en-US", "US", "FEMALE", "NEUTRAL", true));
        var wrongModelAsset = assetRepository.saveAndFlush(new FileAssetEntity(
                FileAssetKind.TTS_AUDIO,
                FileAssetStatus.READY,
                "voxprep-assets",
                "tts/audio/wrong.mp3",
                "audio/mpeg",
                128,
                String.valueOf('c').repeat(64)));
        var config = assetRepository.saveAndFlush(new FileAssetEntity(
                FileAssetKind.TTS_CONFIG,
                FileAssetStatus.READY,
                "voxprep-assets",
                "tts/models/wrong.json",
                "application/json",
                128,
                String.valueOf('d').repeat(64)));

        assertThatThrownBy(() -> modelRepository.saveAndFlush(new TtsVoiceModelEntity(
                        "model-wrong-kind",
                        voice,
                        TtsEngine.PIPER,
                        "1.3.0",
                        "wrong-v1",
                        wrongModelAsset.getId(),
                        config.getId(),
                        String.valueOf('c').repeat(64),
                        String.valueOf('d').repeat(64),
                        TtsVoiceModelStatus.ACTIVE,
                        "MIT",
                        "https://example.invalid/license",
                        true,
                        Instant.parse("2026-11-02T18:00:00Z"))))
                .isInstanceOf(DataIntegrityViolationException.class);
    }
}
