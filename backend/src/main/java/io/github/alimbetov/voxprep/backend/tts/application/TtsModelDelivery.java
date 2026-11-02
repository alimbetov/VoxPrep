package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import java.net.URI;
import java.util.UUID;

public record TtsModelDelivery(
        UUID voiceModelId,
        TtsEngine engine,
        String engineVersion,
        String modelVersion,
        Artifact model,
        Artifact config) {

    public record Artifact(
            UUID assetId,
            URI downloadUrl,
            String sha256,
            long sizeBytes,
            String mediaType) {
    }
}
