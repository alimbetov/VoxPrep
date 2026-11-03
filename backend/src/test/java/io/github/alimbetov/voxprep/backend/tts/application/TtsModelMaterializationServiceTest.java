package io.github.alimbetov.voxprep.backend.tts.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.asset.application.FileAssetIngestService;
import io.github.alimbetov.voxprep.backend.asset.application.ObjectStoragePort;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsVoiceModelStatus;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelRepository;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceRepository;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class TtsModelMaterializationServiceTest {

    @Test
    void materializesPinnedArtifactsThroughSharedAssetLifecycle() throws Exception {
        byte[] modelBytes = "model-bytes".getBytes(StandardCharsets.UTF_8);
        byte[] configBytes = "{}".getBytes(StandardCharsets.UTF_8);
        String modelSha = sha256(modelBytes);
        String configSha = sha256(configBytes);
        TtsModelSelector selector = new TtsModelSelector("en_US", "lessac", "high");
        TtsModelCatalogGateway.ModelDescriptor descriptor = descriptor(modelSha, configSha);

        TtsVoiceRepository voiceRepository = mock(TtsVoiceRepository.class);
        TtsVoiceModelRepository modelRepository = mock(TtsVoiceModelRepository.class);
        FileAssetRepository assetRepository = mock(FileAssetRepository.class);
        FileAssetIngestService ingestService = mock(FileAssetIngestService.class);
        ObjectStoragePort objectStorage = mock(ObjectStoragePort.class);
        TtsModelArtifactSource artifactSource = mock(TtsModelArtifactSource.class);
        TtsVoiceEntity voice = mock(TtsVoiceEntity.class);
        FileAssetEntity modelAsset = mock(FileAssetEntity.class);
        FileAssetEntity configAsset = mock(FileAssetEntity.class);
        UUID modelAssetId = UUID.randomUUID();
        UUID configAssetId = UUID.randomUUID();

        when(modelRepository.findByCode(selector.modelCode())).thenReturn(Optional.empty());
        when(voiceRepository.findByCode(selector.voiceCode())).thenReturn(Optional.of(voice));
        when(objectStorage.defaultBucket()).thenReturn("voxprep");
        when(assetRepository.findByBucketAndObjectKey(any(), any())).thenReturn(Optional.empty());
        when(artifactSource.fetch(any())).thenAnswer(invocation -> {
            TtsModelArtifactSource.ArtifactRequest request = invocation.getArgument(0);
            return request.url().endsWith(".json") ? configBytes : modelBytes;
        });
        when(modelAsset.getId()).thenReturn(modelAssetId);
        when(configAsset.getId()).thenReturn(configAssetId);
        when(ingestService.ingest(any())).thenReturn(modelAsset, configAsset);
        when(modelRepository.saveAndFlush(any())).thenAnswer(invocation -> invocation.getArgument(0));

        TtsModelMaterializationService service = new TtsModelMaterializationService(
                voiceRepository, modelRepository, assetRepository, ingestService, objectStorage, artifactSource);

        var model = service.materialize(selector, descriptor);

        assertThat(model.getStatus()).isEqualTo(TtsVoiceModelStatus.READY_FOR_REVIEW);
        assertThat(model.getSourceProvider()).isEqualTo("huggingface");
        assertThat(model.getSourceRepository()).isEqualTo("rhasspy/piper-voices");
        assertThat(model.getSourceRevision()).isEqualTo("rev-1");
        assertThat(model.getModelAssetId()).isEqualTo(modelAssetId);
        assertThat(model.getConfigAssetId()).isEqualTo(configAssetId);
        assertThat(model.isCommercialUseReviewed()).isFalse();
    }

    @Test
    void rejectsChecksumMismatchBeforeAssetIngest() throws Exception {
        byte[] corrupt = "corrupt".getBytes(StandardCharsets.UTF_8);
        TtsModelSelector selector = new TtsModelSelector("en_US", "lessac", "high");
        TtsModelCatalogGateway.ModelDescriptor descriptor = descriptor(
                sha256("expected".getBytes(StandardCharsets.UTF_8)),
                sha256("{}".getBytes(StandardCharsets.UTF_8)));

        TtsVoiceRepository voiceRepository = mock(TtsVoiceRepository.class);
        TtsVoiceModelRepository modelRepository = mock(TtsVoiceModelRepository.class);
        FileAssetRepository assetRepository = mock(FileAssetRepository.class);
        FileAssetIngestService ingestService = mock(FileAssetIngestService.class);
        ObjectStoragePort objectStorage = mock(ObjectStoragePort.class);
        TtsModelArtifactSource artifactSource = mock(TtsModelArtifactSource.class);
        when(modelRepository.findByCode(selector.modelCode())).thenReturn(Optional.empty());
        when(voiceRepository.findByCode(selector.voiceCode())).thenReturn(Optional.of(mock(TtsVoiceEntity.class)));
        when(artifactSource.fetch(any())).thenReturn(corrupt);

        TtsModelMaterializationService service = new TtsModelMaterializationService(
                voiceRepository, modelRepository, assetRepository, ingestService, objectStorage, artifactSource);

        assertThatThrownBy(() -> service.materialize(selector, descriptor))
                .isInstanceOf(TtsModelMaterializationService.TtsModelIntegrityException.class)
                .hasMessageContaining("model SHA-256 mismatch");
        verify(ingestService, never()).ingest(any());
        verify(modelRepository, never()).saveAndFlush(any());
    }

    private static TtsModelCatalogGateway.ModelDescriptor descriptor(String modelSha, String configSha) {
        return new TtsModelCatalogGateway.ModelDescriptor(
                "huggingface",
                "rhasspy/piper-voices",
                "rev-1",
                "1.2.0",
                "en_US-lessac-high",
                "https://huggingface.co/rhasspy/piper-voices/resolve/rev-1/model.onnx",
                "https://huggingface.co/rhasspy/piper-voices/resolve/rev-1/model.onnx.json",
                modelSha,
                configSha,
                "MIT",
                "https://example.invalid/license");
    }

    private static String sha256(byte[] bytes) throws Exception {
        return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    }
}
