package io.github.alimbetov.voxprep.backend.tts.web;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
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
import java.time.Instant;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

@ActiveProfiles("test")
@SpringBootTest
@Transactional
class TtsModelDeliveryIntegrationTest {

    @Autowired private WebApplicationContext context;
    @Autowired private WorkerDeliveryProperties workerProperties;
    @Autowired private FileAssetRepository assetRepository;
    @Autowired private TtsVoiceRepository voiceRepository;
    @Autowired private TtsVoiceModelRepository modelRepository;
    @Autowired private S3Client s3Client;
    private MockMvc mockMvc;

    @BeforeEach
    void setUp() { mockMvc = MockMvcBuilders.webAppContextSetup(context).build(); }

    @Test
    void bearerTokenProtectsRawModelAndConfigDownloads() throws Exception {
        var voice = voiceRepository.saveAndFlush(new TtsVoiceEntity(
                "voice-http-contract", "US English", "en-US", "US", "FEMALE", "NEUTRAL", true));
        var modelBytes = "onnx-model".getBytes(java.nio.charset.StandardCharsets.UTF_8);
        var configBytes = "{}".getBytes(java.nio.charset.StandardCharsets.UTF_8);
        var modelHash = sha256(modelBytes);
        var configHash = sha256(configBytes);
        var modelAsset = saveAsset("tts/models/http-contract.onnx", "application/octet-stream", modelBytes, modelHash,
                FileAssetKind.TTS_MODEL);
        var configAsset = saveAsset("tts/models/http-contract.onnx.json", "application/json", configBytes, configHash,
                FileAssetKind.TTS_CONFIG);
        var model = modelRepository.saveAndFlush(new TtsVoiceModelEntity(
                "model-http-contract", voice, TtsEngine.PIPER, "1.3.0", "http-v1",
                modelAsset.getId(), configAsset.getId(), modelHash, configHash, TtsVoiceModelStatus.ACTIVE,
                "MIT", "https://example.invalid/license", true, Instant.parse("2026-11-02T18:00:00Z")));

        mockMvc.perform(get("/internal/v1/tts/models/{id}/model", model.getId()))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(get("/internal/v1/tts/models/{id}/model", model.getId())
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + workerProperties.getApiKey()))
                .andExpect(status().isOk())
                .andExpect(header().string("X-Content-SHA256", modelHash))
                .andExpect(content().bytes(modelBytes));
        mockMvc.perform(get("/internal/v1/tts/models/{id}/config", model.getId())
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + workerProperties.getApiKey()))
                .andExpect(status().isOk())
                .andExpect(content().bytes(configBytes));
    }

    private FileAssetEntity saveAsset(String key, String mediaType, byte[] bytes, String hash, FileAssetKind kind) {
        s3Client.putObject(PutObjectRequest.builder().bucket("voxprep-assets").key(key).contentType(mediaType).build(),
                RequestBody.fromBytes(bytes));
        return assetRepository.saveAndFlush(new FileAssetEntity(
                kind, FileAssetStatus.READY, "voxprep-assets", key, mediaType, bytes.length, hash));
    }

    private static String sha256(byte[] value) throws Exception {
        return java.util.HexFormat.of().formatHex(java.security.MessageDigest.getInstance("SHA-256").digest(value));
    }
}
