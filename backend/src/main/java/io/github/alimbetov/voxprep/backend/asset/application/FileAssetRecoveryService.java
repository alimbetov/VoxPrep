package io.github.alimbetov.voxprep.backend.asset.application;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.HexFormat;
import java.util.Objects;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Fail-closed recovery of an ingest interrupted after durable REGISTERED persistence.
 *
 * <p>Does not delete objects, does not retry uploads and never resurrects a FAILED or
 * QUARANTINED asset. Network I/O takes place outside the database row lock.
 */
@Service
public class FileAssetRecoveryService {

    private final FileAssetRepository repository;
    private final ObjectStoragePort storage;
    private final TransactionTemplate transactions;
    private final Clock clock = Clock.systemUTC();

    public FileAssetRecoveryService(
            FileAssetRepository repository,
            ObjectStoragePort storage,
            TransactionTemplate transactions) {
        this.repository = Objects.requireNonNull(repository, "repository");
        this.storage = Objects.requireNonNull(storage, "storage");
        this.transactions = Objects.requireNonNull(transactions, "transactions");
    }

    public RecoveryResult reconcile(UUID assetId, Duration minimumAge) {
        Objects.requireNonNull(assetId, "assetId");
        Objects.requireNonNull(minimumAge, "minimumAge");
        if (minimumAge.isNegative()) {
            throw new IllegalArgumentException("minimumAge must be non-negative");
        }

        var initial = repository.findById(assetId).orElse(null);
        if (initial == null) {
            return RecoveryResult.NOT_FOUND;
        }
        if (initial.getStatus() != FileAssetStatus.REGISTERED) {
            return RecoveryResult.ALREADY_SETTLED;
        }

        Instant cutoff = clock.instant().minus(minimumAge);
        if (initial.getCreatedAt() == null || initial.getCreatedAt().isAfter(cutoff)) {
            return RecoveryResult.TOO_RECENT;
        }

        byte[] stored;
        try {
            stored = storage.read(initial.getBucket(), initial.getObjectKey());
        } catch (RuntimeException exception) {
            // A missing object or transient RustFS outage must not be mistaken for
            // verified corruption. Preserve REGISTERED for safe later inspection/retry.
            return RecoveryResult.STORAGE_UNAVAILABLE;
        }

        boolean verified = stored.length == initial.getSizeBytes()
                && sha256(stored).equals(initial.getSha256());

        return Objects.requireNonNull(transactions.execute(status -> {
            var current = repository.findByIdForUpdate(assetId).orElse(null);
            if (current == null) {
                return RecoveryResult.NOT_FOUND;
            }
            if (current.getStatus() != FileAssetStatus.REGISTERED) {
                return RecoveryResult.ALREADY_SETTLED;
            }
            if (current.getCreatedAt() == null || current.getCreatedAt().isAfter(cutoff)) {
                return RecoveryResult.TOO_RECENT;
            }
            if (!Objects.equals(current.getBucket(), initial.getBucket())
                    || !Objects.equals(current.getObjectKey(), initial.getObjectKey())
                    || current.getSizeBytes() != initial.getSizeBytes()
                    || !Objects.equals(current.getSha256(), initial.getSha256())) {
                return RecoveryResult.ALREADY_SETTLED;
            }
            if (verified) {
                current.markReady();
            } else {
                current.markQuarantined();
            }
            repository.saveAndFlush(current);
            return verified ? RecoveryResult.RECOVERED_READY : RecoveryResult.QUARANTINED;
        }));
    }

    private static String sha256(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    public enum RecoveryResult {
        NOT_FOUND,
        ALREADY_SETTLED,
        TOO_RECENT,
        STORAGE_UNAVAILABLE,
        RECOVERED_READY,
        QUARANTINED
    }
}
