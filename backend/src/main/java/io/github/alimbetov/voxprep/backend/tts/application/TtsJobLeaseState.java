package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.tts.domain.TtsJobStatus;
import java.time.Instant;
import java.util.UUID;

public record TtsJobLeaseState(
        UUID jobId,
        TtsJobStatus status,
        String leaseOwner,
        UUID leaseToken,
        Instant leaseUntil,
        int attemptCount) {
}
