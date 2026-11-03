package io.github.alimbetov.voxprep.backend.asset.application;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import java.time.Clock;
import java.time.Duration;
import java.util.EnumMap;
import java.util.Map;
import java.util.Objects;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

/**
 * On-demand bounded reconciliation of stale REGISTERED file assets.
 *
 * <p>Does not schedule itself or delete storage objects. A single invocation reads
 * at most maxBatchSize IDs. Multiple backend instances may scan the same candidate;
 * the per-asset recovery service rechecks state under a database row lock.
 */
@Service
public class FileAssetRecoveryBatchService {

    private static final int MAX_BATCH_SIZE = 100;

    private final FileAssetRepository assets;
    private final FileAssetRecoveryService recovery;
    private final Clock clock = Clock.systemUTC();

    public FileAssetRecoveryBatchService(FileAssetRepository assets, FileAssetRecoveryService recovery) {
        this.assets = Objects.requireNonNull(assets, "assets");
        this.recovery = Objects.requireNonNull(recovery, "recovery");
    }

    public BatchResult reconcileStale(Duration minimumAge, int batchSize) {
        Objects.requireNonNull(minimumAge, "minimumAge");
        if (minimumAge.isNegative() || minimumAge.isZero()) {
            throw new IllegalArgumentException("minimumAge must be positive");
        }
        if (batchSize < 1 || batchSize > MAX_BATCH_SIZE) {
            throw new IllegalArgumentException("batchSize must be between 1 and " + MAX_BATCH_SIZE);
        }

        var ids = assets.findStaleAssetIds(
                FileAssetStatus.REGISTERED,
                clock.instant().minus(minimumAge),
                PageRequest.of(0, batchSize));
        var counts = new EnumMap<FileAssetRecoveryService.RecoveryResult, Integer>(
                FileAssetRecoveryService.RecoveryResult.class);
        for (var id : ids) {
            var result = recovery.reconcile(id, minimumAge);
            counts.merge(result, 1, Integer::sum);
        }
        return new BatchResult(ids.size(), Map.copyOf(counts));
    }

    public record BatchResult(
            int inspected,
            Map<FileAssetRecoveryService.RecoveryResult, Integer> outcomes) {
        public BatchResult {
            outcomes = Map.copyOf(outcomes);
        }
    }
}
