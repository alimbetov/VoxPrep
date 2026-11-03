package io.github.alimbetov.voxprep.backend.asset.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import java.time.Duration;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Pageable;

@ExtendWith(MockitoExtension.class)
class FileAssetRecoveryBatchIntegrationTest {

    @Mock private FileAssetRepository assets;
    @Mock private FileAssetRecoveryService recovery;

    @Test
    void boundedBatchScansOnlySelectedIdsAndReportsOutcomes() {
        var first = UUID.randomUUID();
        var second = UUID.randomUUID();
        when(assets.findStaleAssetIds(eq(FileAssetStatus.REGISTERED), any(), any(Pageable.class)))
                .thenReturn(List.of(first, second));
        when(recovery.reconcile(first, Duration.ofMinutes(5)))
                .thenReturn(FileAssetRecoveryService.RecoveryResult.RECOVERED_READY);
        when(recovery.reconcile(second, Duration.ofMinutes(5)))
                .thenReturn(FileAssetRecoveryService.RecoveryResult.STORAGE_UNAVAILABLE);

        var batch = new FileAssetRecoveryBatchService(assets, recovery);
        var result = batch.reconcileStale(Duration.ofMinutes(5), 2);

        assertThat(result.inspected()).isEqualTo(2);
        assertThat(result.outcomes())
                .containsEntry(FileAssetRecoveryService.RecoveryResult.RECOVERED_READY, 1)
                .containsEntry(FileAssetRecoveryService.RecoveryResult.STORAGE_UNAVAILABLE, 1);
        var page = ArgumentCaptor.forClass(Pageable.class);
        verify(assets).findStaleAssetIds(eq(FileAssetStatus.REGISTERED), any(), page.capture());
        assertThat(page.getValue().getPageSize()).isEqualTo(2);
        verify(recovery).reconcile(first, Duration.ofMinutes(5));
        verify(recovery).reconcile(second, Duration.ofMinutes(5));
    }

    @Test
    void rejectsUnlimitedScansAndZeroMinimumAgeWithoutDatabaseCalls() {
        var batch = new FileAssetRecoveryBatchService(assets, recovery);
        assertThatThrownBy(() -> batch.reconcileStale(Duration.ZERO, 1))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> batch.reconcileStale(Duration.ofMinutes(5), 101))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> batch.reconcileStale(Duration.ofMinutes(5), 0))
                .isInstanceOf(IllegalArgumentException.class);
        verify(assets, never()).findStaleAssetIds(any(), any(), any());
    }
}
