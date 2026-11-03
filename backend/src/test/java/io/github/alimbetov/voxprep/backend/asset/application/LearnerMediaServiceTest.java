package io.github.alimbetov.voxprep.backend.asset.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class LearnerMediaServiceTest {

    @Mock private FileAssetRepository assetRepository;
    @Mock private ObjectStoragePort objectStorage;
    @Mock private FileAssetEntity asset;

    private LearnerMediaService service;

    @BeforeEach
    void setUp() {
        service = new LearnerMediaService(assetRepository, objectStorage);
    }

    @Test
    void describeExposesOnlyReadyLearnerAssetMetadataWithoutStorageRead() {
        UUID assetId = UUID.randomUUID();
        byte[] bytes = "media".getBytes(StandardCharsets.UTF_8);
        stubReadyAsset(assetId, FileAssetKind.CONTENT_IMAGE, bytes);

        LearnerMediaService.MediaDescriptor descriptor = service.describe(assetId);

        assertThat(descriptor.etag()).isEqualTo('"' + sha256(bytes) + '"');
        assertThat(descriptor.mediaType()).isEqualTo("image/webp");
        assertThat(descriptor.sizeBytes()).isEqualTo(bytes.length);
        verify(objectStorage, never()).read("media", "media/content/item.webp");
    }

    @Test
    void rejectsInternalTtsModelEvenWhenReady() {
        UUID assetId = UUID.randomUUID();
        when(assetRepository.findById(assetId)).thenReturn(Optional.of(asset));
        when(asset.getKind()).thenReturn(FileAssetKind.TTS_MODEL);
        when(asset.getStatus()).thenReturn(FileAssetStatus.READY);

        assertThatThrownBy(() -> service.describe(assetId))
                .isInstanceOf(LearnerMediaService.MediaUnavailableException.class);
    }

    @Test
    void readVerifiesChecksumAndSizeBeforeReturningBytes() {
        UUID assetId = UUID.randomUUID();
        byte[] bytes = "verified".getBytes(StandardCharsets.UTF_8);
        LearnerMediaService.MediaDescriptor descriptor = new LearnerMediaService.MediaDescriptor(
                assetId, "media", "media/content/item.webp", "image/webp",
                bytes.length, sha256(bytes), '"' + sha256(bytes) + '"');
        when(objectStorage.read("media", "media/content/item.webp")).thenReturn(bytes.clone());

        LearnerMediaService.MediaContent content = service.read(descriptor);

        assertThat(content.bytes()).containsExactly(bytes);
    }

    @Test
    void corruptReadBackQuarantinesReadyAssetAndFailsClosed() {
        UUID assetId = UUID.randomUUID();
        byte[] expected = "expected".getBytes(StandardCharsets.UTF_8);
        LearnerMediaService.MediaDescriptor descriptor = new LearnerMediaService.MediaDescriptor(
                assetId, "media", "media/content/item.webp", "image/webp",
                expected.length, sha256(expected), '"' + sha256(expected) + '"');
        when(objectStorage.read("media", "media/content/item.webp"))
                .thenReturn("corrupt".getBytes(StandardCharsets.UTF_8));
        when(assetRepository.findById(assetId)).thenReturn(Optional.of(asset));
        when(asset.getStatus()).thenReturn(FileAssetStatus.READY);

        assertThatThrownBy(() -> service.read(descriptor))
                .isInstanceOf(LearnerMediaService.MediaIntegrityException.class);

        verify(asset).markQuarantined();
        verify(assetRepository).saveAndFlush(asset);
    }

    private void stubReadyAsset(UUID assetId, FileAssetKind kind, byte[] bytes) {
        when(assetRepository.findById(assetId)).thenReturn(Optional.of(asset));
        when(asset.getId()).thenReturn(assetId);
        when(asset.getKind()).thenReturn(kind);
        when(asset.getStatus()).thenReturn(FileAssetStatus.READY);
        when(asset.getBucket()).thenReturn("media");
        when(asset.getObjectKey()).thenReturn("media/content/item.webp");
        when(asset.getMediaType()).thenReturn("image/webp");
        when(asset.getSizeBytes()).thenReturn((long) bytes.length);
        when(asset.getSha256()).thenReturn(sha256(bytes));
    }

    private static String sha256(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (Exception exception) {
            throw new IllegalStateException(exception);
        }
    }
}
