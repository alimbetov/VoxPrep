package io.github.alimbetov.voxprep.backend.tts.application;

import java.util.Optional;

public interface TtsModelCatalogGateway {

    Optional<ModelDescriptor> resolve(TtsModelSelector selector);

    record ModelDescriptor(
            String sourceProvider,
            String sourceRepository,
            String sourceRevision,
            String engineVersion,
            String modelVersion,
            String modelUrl,
            String configUrl,
            String modelSha256,
            String configSha256,
            String licenseName,
            String licenseReference) {
    }
}
