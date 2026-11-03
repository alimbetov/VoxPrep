package io.github.alimbetov.voxprep.backend.asset.application;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.HexFormat;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

/**
 * Run each method in a separate Maven invocation, with RustFS stopped between
 * the seed and outage methods and restarted before the final method.
 */
@ActiveProfiles("test")
@SpringBootTest
class RustFsRestartAcceptanceTest {

    private static final String KEY = "h2/fault-injection/restart-acceptance.mp3";
    private static final byte[] PAYLOAD = "rustfs-restart-acceptance".getBytes(StandardCharsets.UTF_8);

    @Autowired private FileAssetRepository assets;
    @Autowired private ObjectStoragePort storage;
    @Autowired private FileAssetRecoveryService recovery;

    @Test
    void seedObjectAndLeaveRegistered() throws Exception {
        String bucket = storage.defaultBucket();
        assertThat(assets.findByBucketAndObjectKey(bucket, KEY)).isEmpty();
        var asset = assets.saveAndFlush(new FileAssetEntity(
                FileAssetKind.TTS_AUDIO, FileAssetStatus.REGISTERED, bucket, KEY,
                "audio/mpeg", PAYLOAD.length, sha256()));
        storage.write(bucket, KEY, "audio/mpeg",
                Map.of("sha256", sha256()), PAYLOAD);
        assertThat(assets.findById(asset.getId()).orElseThrow().getStatus())
                .isEqualTo(FileAssetStatus.REGISTERED);
    }

    @Test
    void outageLeavesRegistered() {
        var asset = fixture();
        assertThat(recovery.reconcile(asset.getId(), Duration.ZERO))
                .isEqualTo(FileAssetRecoveryService.RecoveryResult.STORAGE_UNAVAILABLE);
        assertThat(assets.findById(asset.getId()).orElseThrow().getStatus())
                .isEqualTo(FileAssetStatus.REGISTERED);
    }

    @Test
    void restartRecoversReady() {
        var asset = fixture();
        assertThat(recovery.reconcile(asset.getId(), Duration.ZERO))
                .isEqualTo(FileAssetRecoveryService.RecoveryResult.RECOVERED_READY);
        assertThat(assets.findById(asset.getId()).orElseThrow().getStatus())
                .isEqualTo(FileAssetStatus.READY);
        assertThat(recovery.reconcile(asset.getId(), Duration.ZERO))
                .isEqualTo(FileAssetRecoveryService.RecoveryResult.ALREADY_SETTLED);
    }

    private FileAssetEntity fixture() {
        return assets.findByBucketAndObjectKey(storage.defaultBucket(), KEY).orElseThrow();
    }

    private static String sha256() throws Exception {
        return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(PAYLOAD));
    }
}
