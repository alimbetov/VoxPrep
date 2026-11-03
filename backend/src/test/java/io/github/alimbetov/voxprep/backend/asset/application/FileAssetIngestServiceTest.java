package io.github.alimbetov.voxprep.backend.asset.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class FileAssetIngestServiceTest {

    @Mock private FileAssetRepository assetRepository;
    @Mock private ObjectStoragePort objectStorage;

    private FileAssetIngestService service;

    @BeforeEach
    void setUp() {
        service = new FileAssetIngestService(assetRepository, objectStorage);
    }

    @Test
    void persistsRegisteredWritesVerifiesAndMarksReady() {
        stubRepositoryRoundTrip();
        byte[] payload = "verified-media".getBytes(StandardCharsets.UTF_8);
        when(objectStorage.read("media", "content/verified.bin")).thenReturn(payload.clone());

        FileAssetEntity asset = service.ingest(new FileAssetIngestService.IngestCommand(
                FileAssetKind.TTS_AUDIO,
                "media",
                "content/verified.bin",
                "application/octet-stream",
                Map.of("source", "test"),
                payload));

        assertThat(asset.getStatus()).isEqualTo(FileAssetStatus.READY);
        assertThat(asset.getSizeBytes()).isEqualTo(payload.length);
        assertThat(asset.getSha256()).isEqualTo(sha256(payload));

        @SuppressWarnings("unchecked")
        ArgumentCaptor<Map<String, String>> metadataCaptor = ArgumentCaptor.forClass(Map.class);
        verify(objectStorage).write(
                eq("media"),
                eq("content/verified.bin"),
                eq("application/octet-stream"),
                metadataCaptor.capture(),
                any(byte[].class));
        assertThat(metadataCaptor.getValue())
                .containsEntry("source", "test")
                .containsEntry("sha256", sha256(payload))
                .containsEntry("size-bytes", Integer.toString(payload.length));
        verify(assetRepository, times(2)).saveAndFlush(any(FileAssetEntity.class));
    }

    @Test
    void storageFailureLeavesDurableFailedState() {
        stubRepositoryRoundTrip();
        byte[] payload = "storage-failure".getBytes(StandardCharsets.UTF_8);
        doThrow(new IllegalStateException("storage offline"))
                .when(objectStorage)
                .write(eq("media"), eq("content/fail.bin"), eq("application/octet-stream"), anyMap(), any(byte[].class));

        assertThatThrownBy(() -> service.ingest(new FileAssetIngestService.IngestCommand(
                        FileAssetKind.TTS_AUDIO,
                        "media",
                        "content/fail.bin",
                        "application/octet-stream",
                        Map.of(),
                        payload)))
                .isInstanceOf(FileAssetIngestService.AssetStorageException.class)
                .hasCauseInstanceOf(IllegalStateException.class);

        ArgumentCaptor<FileAssetEntity> assetCaptor = ArgumentCaptor.forClass(FileAssetEntity.class);
        verify(assetRepository, times(2)).saveAndFlush(assetCaptor.capture());
        assertThat(assetCaptor.getAllValues().getLast().getStatus()).isEqualTo(FileAssetStatus.FAILED);
    }

    @Test
    void readBackMismatchQuarantinesAsset() {
        stubRepositoryRoundTrip();
        byte[] payload = "expected".getBytes(StandardCharsets.UTF_8);
        when(objectStorage.read("media", "content/corrupt.bin"))
                .thenReturn("corrupted".getBytes(StandardCharsets.UTF_8));

        assertThatThrownBy(() -> service.ingest(new FileAssetIngestService.IngestCommand(
                        FileAssetKind.TTS_AUDIO,
                        "media",
                        "content/corrupt.bin",
                        "application/octet-stream",
                        Map.of(),
                        payload)))
                .isInstanceOf(FileAssetIngestService.AssetIntegrityException.class);

        ArgumentCaptor<FileAssetEntity> assetCaptor = ArgumentCaptor.forClass(FileAssetEntity.class);
        verify(assetRepository, times(2)).saveAndFlush(assetCaptor.capture());
        assertThat(assetCaptor.getAllValues().getLast().getStatus()).isEqualTo(FileAssetStatus.QUARANTINED);
    }

    @Test
    void readyAssetCannotMoveBackIntoFailureLifecycle() {
        FileAssetEntity asset = new FileAssetEntity(
                FileAssetKind.TTS_AUDIO,
                FileAssetStatus.REGISTERED,
                "media",
                "content/immutable.bin",
                "application/octet-stream",
                1,
                String.valueOf('a').repeat(64));

        asset.markReady();

        assertThatThrownBy(asset::markFailed)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("READY")
                .hasMessageContaining("FAILED");
    }

    private void stubRepositoryRoundTrip() {
        when(assetRepository.saveAndFlush(any(FileAssetEntity.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
    }

    private static String sha256(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (Exception exception) {
            throw new IllegalStateException(exception);
        }
    }
}
