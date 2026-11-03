package io.github.alimbetov.voxprep.backend.asset.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.HexFormat;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

@ActiveProfiles("test")
@SpringBootTest
class FileAssetRecoveryIntegrationTest {

    @Autowired private FileAssetRepository assets;
    @Autowired private FileAssetRecoveryService recovery;
    @MockitoBean private ObjectStoragePort storage;

    @Test
    void recoversVerifiedRegisteredAssetAndIsIdempotent() throws Exception {
        byte[] payload = "durable-upload".getBytes(StandardCharsets.UTF_8);
        var registered = registered(payload);
        when(storage.openRead(registered.getBucket(), registered.getObjectKey())).thenReturn(new ByteArrayInputStream(payload.clone()));

        assertThat(recovery.reconcile(registered.getId(), Duration.ZERO))
                .isEqualTo(FileAssetRecoveryService.RecoveryResult.RECOVERED_READY);
        assertThat(assets.findById(registered.getId()).orElseThrow().getStatus())
                .isEqualTo(FileAssetStatus.READY);
        assertThat(recovery.reconcile(registered.getId(), Duration.ZERO))
                .isEqualTo(FileAssetRecoveryService.RecoveryResult.ALREADY_SETTLED);
    }

    @Test
    void corruptedObjectIsQuarantinedNotPublished() throws Exception {
        byte[] payload = "expected".getBytes(StandardCharsets.UTF_8);
        var registered = registered(payload);
        when(storage.openRead(registered.getBucket(), registered.getObjectKey()))
                .thenReturn(new ByteArrayInputStream("corrupted".getBytes(StandardCharsets.UTF_8)));

        assertThat(recovery.reconcile(registered.getId(), Duration.ZERO))
                .isEqualTo(FileAssetRecoveryService.RecoveryResult.QUARANTINED);
        assertThat(assets.findById(registered.getId()).orElseThrow().getStatus())
                .isEqualTo(FileAssetStatus.QUARANTINED);
        assertThat(recovery.reconcile(registered.getId(), Duration.ZERO))
                .isEqualTo(FileAssetRecoveryService.RecoveryResult.ALREADY_SETTLED);
    }

    @Test
    void temporaryStorageOutagePreservesRegisteredForRetry() throws Exception {
        var registered = registered("retry-me".getBytes(StandardCharsets.UTF_8));
        when(storage.openRead(registered.getBucket(), registered.getObjectKey()))
                .thenThrow(new IllegalStateException("RustFS temporarily unavailable"));

        assertThat(recovery.reconcile(registered.getId(), Duration.ZERO))
                .isEqualTo(FileAssetRecoveryService.RecoveryResult.STORAGE_UNAVAILABLE);
        assertThat(assets.findById(registered.getId()).orElseThrow().getStatus())
                .isEqualTo(FileAssetStatus.REGISTERED);
    }

    @Test
    void interruptedStreamPreservesRegisteredAndCanBeRetried() throws Exception {
        byte[] payload = "stream-crash-restart".getBytes(StandardCharsets.UTF_8);
        var registered = registered(payload);
        when(storage.openRead(registered.getBucket(), registered.getObjectKey()))
                .thenReturn(new InputStream() {
                    @Override
                    public int read() throws IOException {
                        throw new IOException("network partition during stream");
                    }
                }, new ByteArrayInputStream(payload));
        assertThat(recovery.reconcile(registered.getId(), Duration.ZERO))
                .isEqualTo(FileAssetRecoveryService.RecoveryResult.STORAGE_UNAVAILABLE);
        assertThat(assets.findById(registered.getId()).orElseThrow().getStatus())
                .isEqualTo(FileAssetStatus.REGISTERED);
        assertThat(recovery.reconcile(registered.getId(), Duration.ZERO))
                .isEqualTo(FileAssetRecoveryService.RecoveryResult.RECOVERED_READY);
    }

    @Test
    void oversizedMetadataRemainsRegisteredWithoutDownloadingObject() throws Exception {
        var large = assets.saveAndFlush(new FileAssetEntity(
                FileAssetKind.TTS_AUDIO, FileAssetStatus.REGISTERED, "voxprep-assets",
                "h2/recovery/" + UUID.randomUUID() + ".mp3", "audio/mpeg",
                64L * 1024 * 1024 + 1, "a".repeat(64)));
        assertThat(recovery.reconcile(large.getId(), Duration.ZERO))
                .isEqualTo(FileAssetRecoveryService.RecoveryResult.TOO_LARGE);
        assertThat(assets.findById(large.getId()).orElseThrow().getStatus())
                .isEqualTo(FileAssetStatus.REGISTERED);
        org.mockito.Mockito.verify(storage, org.mockito.Mockito.never())
                .openRead(large.getBucket(), large.getObjectKey());
    }

    @Test
    void staleAgeGuardPreventsTouchingActiveIngest() throws Exception {
        var registered = registered("in-flight".getBytes(StandardCharsets.UTF_8));
        assertThat(recovery.reconcile(registered.getId(), Duration.ofHours(1)))
                .isEqualTo(FileAssetRecoveryService.RecoveryResult.TOO_RECENT);
        assertThat(assets.findById(registered.getId()).orElseThrow().getStatus())
                .isEqualTo(FileAssetStatus.REGISTERED);
    }

    private FileAssetEntity registered(byte[] payload) throws Exception {
        return assets.saveAndFlush(new FileAssetEntity(
                FileAssetKind.TTS_AUDIO, FileAssetStatus.REGISTERED,
                "voxprep-assets", "h2/recovery/" + UUID.randomUUID() + ".mp3",
                "audio/mpeg", payload.length,
                HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(payload))));
    }
}
