package io.github.alimbetov.voxprep.backend.asset.application;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import java.io.IOException;
import java.io.InputStream;
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

    /** Explicit per-object cap; oversized assets require a separate, deliberate recovery path. */
    private static final long MAX_VERIFICATION_BYTES = 64L * 1024 * 1024;

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

        if (initial.getSizeBytes() > MAX_VERIFICATION_BYTES) {
            return RecoveryResult.TOO_LARGE;
        }
        boolean verified;
        try (InputStream stream = storage.openRead(initial.getBucket(), initial.getObjectKey())) {
            var digest = MessageDigest.getInstance("SHA-256");
            byte[] buffer = new byte[8192];
            long length = 0;
            int count;
            while ((count = stream.read(buffer)) != -1) {
                length += count;
                if (length > MAX_VERIFICATION_BYTES) {
                    // Do not quarantine a file when verification exceeds the configured budget.
                    return RecoveryResult.TOO_LARGE;
                }
                digest.update(buffer, 0, count);
            }
            verified = length == initial.getSizeBytes()
                    && HexFormat.of().formatHex(digest.digest()).equals(initial.getSha256());
        } catch (IOException | RuntimeException exception) {
            // A missing object, partial stream or transient RustFS outage stays retryable.
            return RecoveryResult.STORAGE_UNAVAILABLE;
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 unavailable", exception);
        }

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

    public enum RecoveryResult {
        NOT_FOUND,
        ALREADY_SETTLED,
        TOO_RECENT,
        TOO_LARGE,
        STORAGE_UNAVAILABLE,
        RECOVERED_READY,
        QUARANTINED
    }
}
