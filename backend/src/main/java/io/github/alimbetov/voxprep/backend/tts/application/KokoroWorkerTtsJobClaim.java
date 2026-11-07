package io.github.alimbetov.voxprep.backend.tts.application;

import java.math.BigDecimal;
import java.util.Objects;
import java.util.UUID;

/** A lease-bound claim joined to its immutable job-level model snapshot. */
public record KokoroWorkerTtsJobClaim(
        WorkerTtsJobClaim job,
        UUID bundleId,
        String bundleModelCode,
        String manifestSha256,
        String voiceCode,
        String voiceArtifactSha256,
        String phonemizerVersion,
        String engineVersion,
        BigDecimal speed) {
    public KokoroWorkerTtsJobClaim {
        Objects.requireNonNull(job, "job");
        Objects.requireNonNull(bundleId, "bundleId");
        Objects.requireNonNull(bundleModelCode, "bundleModelCode");
        Objects.requireNonNull(manifestSha256, "manifestSha256");
        Objects.requireNonNull(voiceCode, "voiceCode");
        Objects.requireNonNull(voiceArtifactSha256, "voiceArtifactSha256");
        Objects.requireNonNull(phonemizerVersion, "phonemizerVersion");
        Objects.requireNonNull(engineVersion, "engineVersion");
        Objects.requireNonNull(speed, "speed");
        if (!job.fingerprint().matches("[0-9a-f]{64}")
                || !manifestSha256.matches("[0-9a-f]{64}")) {
            throw new IllegalArgumentException("Invalid immutable Kokoro claim identity");
        }
    }
}
