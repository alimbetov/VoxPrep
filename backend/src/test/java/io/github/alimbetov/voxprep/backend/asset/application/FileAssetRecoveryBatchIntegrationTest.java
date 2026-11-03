package io.github.alimbetov.voxprep.backend.asset.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
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
class FileAssetRecoveryBatchIntegrationTest {

    @Autowired private FileAssetRepository assets;
    @Autowired private FileAssetRecoveryBatchService batch;
    @MockitoBean private ObjectStoragePort storage;

    @Test
    void boundedBatchProcessesOnlyOneCandidateAndReportsOutcome() throws Exception {
        var first = registered("h2-batch-first");
        var second = registered("h2-batch-second");
        byte[] firstBytes = "h2-batch-first".getBytes(StandardCharsets.UTF_8);
        byte[] secondBytes = "h2-batch-second".getBytes(StandardCharsets.UTF_8);
        when(storage.read(first.getBucket(), first.getObjectKey())).thenReturn(firstBytes);
        when(storage.read(second.getBucket(), second.getObjectKey())).thenReturn(secondBytes);

        var result = batch.reconcileStale(Duration.ofMillis(1), 1);
        assertThat(result.inspected()).isEqualTo(1);
        assertThat(result.outcomes().values().stream().mapToInt(Integer::intValue).sum()).isEqualTo(1);
        var states = java.util.List.of(
                assets.findById(first.getId()).orElseThrow().getStatus(),
                assets.findById(second.getId()).orElseThrow().getStatus());
        assertThat(states).contains(FileAssetStatus.REGISTERED);
        assertThat(states).contains(FileAssetStatus.READY);
    }

    @Test
    void rejectsUnlimitedScansAndZeroMinimumAge() {
        assertThatThrownBy(() -> batch.reconcileStale(Duration.ZERO, 1))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> batch.reconcileStale(Duration.ofMinutes(5), 101))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> batch.reconcileStale(Duration.ofMinutes(5), 0))
                .isInstanceOf(IllegalArgumentException.class);
    }

    private FileAssetEntity registered(String text) throws Exception {
        byte[] payload = text.getBytes(StandardCharsets.UTF_8);
        return assets.saveAndFlush(new FileAssetEntity(
                FileAssetKind.TTS_AUDIO, FileAssetStatus.REGISTERED,
                "voxprep-assets", "h2/batch/" + UUID.randomUUID() + ".mp3",
                "audio/mpeg", payload.length,
                HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(payload))));
    }
}
