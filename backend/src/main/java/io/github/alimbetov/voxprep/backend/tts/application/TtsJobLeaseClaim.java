package io.github.alimbetov.voxprep.backend.tts.application;

import java.time.Instant;
import java.util.UUID;

public record TtsJobLeaseClaim(
        UUID jobId,
        UUID voiceModelId,
        String inputText,
        String inputSha256,
        String leaseOwner,
        UUID leaseToken,
        Instant leaseUntil,
        int attemptCount) {
}
