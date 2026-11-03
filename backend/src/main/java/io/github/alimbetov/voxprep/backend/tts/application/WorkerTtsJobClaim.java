package io.github.alimbetov.voxprep.backend.tts.application;

import java.time.Instant;
import java.util.UUID;

public record WorkerTtsJobClaim(
        UUID jobId,
        UUID fileId,
        UUID contentRevisionId,
        String audioRole,
        String normalizedTtsText,
        String language,
        UUID voiceModelId,
        String voiceModelCode,
        String modelSha256,
        String configSha256,
        String fingerprint,
        UUID leaseToken,
        Instant leaseUntil) {
}
