package io.github.alimbetov.voxprep.backend.asset.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class AdminMediaServiceTest {

    @Mock private FileAssetIngestService ingestService;
    @Mock private FileAssetRepository assetRepository;
    @Mock private ObjectStoragePort objectStorage;
    @Mock private FileAssetEntity asset;

    private AdminMediaService service;

    @BeforeEach
    void setUp() {
        service = new AdminMediaService(ingestService, assetRepository, objectStorage);
    }

    @Test
    void uploadUsesDetectedMimeGeneratedKeyAndDefaultBucket() {
        UUID assetId = UUID.randomUUID();
        byte[] jpeg = {(byte) 0xff, (byte) 0xd8, (byte) 0xff, 0x01};
        when(objectStorage.defaultBucket()).thenReturn("voxprep-media");
        when(asset.getId()).thenReturn(assetId);
        when(asset.getKind()).thenReturn(FileAssetKind.COVER_IMAGE);
        when(asset.getStatus()).thenReturn(FileAssetStatus.READY);
        when(asset.getMediaType()).thenReturn("image/jpeg");
        when(asset.getSizeBytes()).thenReturn((long) jpeg.length);
        when(asset.getSha256()).thenReturn("a".repeat(64));
        when(ingestService.ingest(any())).thenReturn(asset);

        AdminMediaService.AssetView view = service.upload(FileAssetKind.COVER_IMAGE, jpeg);

        assertThat(view.assetId()).isEqualTo(assetId);
        ArgumentCaptor<FileAssetIngestService.IngestCommand> commandCaptor =
                ArgumentCaptor.forClass(FileAssetIngestService.IngestCommand.class);
        verify(ingestService).ingest(commandCaptor.capture());
        FileAssetIngestService.IngestCommand command = commandCaptor.getValue();
        assertThat(command.bucket()).isEqualTo("voxprep-media");
        assertThat(command.mediaType()).isEqualTo("image/jpeg");
        assertThat(command.objectKey()).startsWith("media/cover/").endsWith(".jpg");
        assertThat(command.metadata()).containsEntry("asset-kind", "COVER_IMAGE");
    }

    @Test
    void uploadRejectsTtsKindsBeforeStorage() {
        assertThatThrownBy(() -> service.upload(FileAssetKind.TTS_AUDIO, new byte[] {1, 2, 3}))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("COVER_IMAGE")
                .hasMessageContaining("CONTENT_IMAGE");
    }

    @Test
    void previewReturnsOnlyReadyImageAssetsThroughStoragePort() {
        UUID assetId = UUID.randomUUID();
        byte[] bytes = {1, 2, 3};
        when(assetRepository.findById(assetId)).thenReturn(Optional.of(asset));
        when(asset.getKind()).thenReturn(FileAssetKind.CONTENT_IMAGE);
        when(asset.getStatus()).thenReturn(FileAssetStatus.READY);
        when(asset.getBucket()).thenReturn("voxprep-media");
        when(asset.getObjectKey()).thenReturn("media/content/a.webp");
        when(asset.getMediaType()).thenReturn("image/webp");
        when(objectStorage.read("voxprep-media", "media/content/a.webp")).thenReturn(bytes);

        AdminMediaService.AssetContent content = service.preview(assetId);

        assertThat(content.mediaType()).isEqualTo("image/webp");
        assertThat(content.bytes()).containsExactly(bytes);
        verify(objectStorage).read("voxprep-media", "media/content/a.webp");
    }

    @Test
    void previewRejectsNonReadyAsset() {
        UUID assetId = UUID.randomUUID();
        when(assetRepository.findById(assetId)).thenReturn(Optional.of(asset));
        when(asset.getKind()).thenReturn(FileAssetKind.COVER_IMAGE);
        when(asset.getStatus()).thenReturn(FileAssetStatus.FAILED);

        assertThatThrownBy(() -> service.preview(assetId))
                .isInstanceOf(java.util.NoSuchElementException.class)
                .hasMessageContaining("not ready");
    }
}
