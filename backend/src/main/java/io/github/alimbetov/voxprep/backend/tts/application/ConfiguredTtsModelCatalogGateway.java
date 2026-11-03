package io.github.alimbetov.voxprep.backend.tts.application;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import org.springframework.stereotype.Component;

/** Catalogue gateway backed by immutable seed configuration. */
@Component
public class ConfiguredTtsModelCatalogGateway implements TtsModelCatalogGateway {

    private final Map<String, ModelDescriptor> models;

    public ConfiguredTtsModelCatalogGateway(TtsProvisioningProperties properties) {
        Objects.requireNonNull(properties, "properties");
        Map<String, ModelDescriptor> indexed = new LinkedHashMap<>();
        for (TtsProvisioningProperties.Seed seed : properties.getSeeds()) {
            String modelCode = seed.selector().modelCode();
            ModelDescriptor previous = indexed.putIfAbsent(modelCode, seed.descriptor());
            if (previous != null) {
                throw new IllegalStateException("Duplicate configured TTS seed: " + modelCode);
            }
        }
        this.models = Map.copyOf(indexed);
    }

    @Override
    public Optional<ModelDescriptor> resolve(TtsModelSelector selector) {
        Objects.requireNonNull(selector, "selector");
        return Optional.ofNullable(models.get(selector.modelCode()));
    }
}
