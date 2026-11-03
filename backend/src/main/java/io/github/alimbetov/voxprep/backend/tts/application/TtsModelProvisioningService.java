package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelRepository;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TtsModelProvisioningService {

    public enum State {
        PRESENT,
        RESOLVABLE,
        MISSING
    }

    public record Resolution(
            TtsModelSelector selector,
            State state,
            TtsVoiceModelEntity existingModel,
            TtsModelCatalogGateway.ModelDescriptor descriptor) {
    }

    private final TtsVoiceModelRepository modelRepository;
    private final List<TtsModelCatalogGateway> catalogGateways;

    public TtsModelProvisioningService(
            TtsVoiceModelRepository modelRepository,
            List<TtsModelCatalogGateway> catalogGateways) {
        this.modelRepository = Objects.requireNonNull(modelRepository, "modelRepository");
        this.catalogGateways = List.copyOf(Objects.requireNonNull(catalogGateways, "catalogGateways"));
    }

    @Transactional(readOnly = true)
    public Resolution resolve(TtsModelSelector selector) {
        Objects.requireNonNull(selector, "selector");
        Optional<TtsVoiceModelEntity> existing = modelRepository.findByCode(selector.modelCode());
        if (existing.isPresent()) {
            return new Resolution(selector, State.PRESENT, existing.orElseThrow(), null);
        }

        for (TtsModelCatalogGateway gateway : catalogGateways) {
            Optional<TtsModelCatalogGateway.ModelDescriptor> descriptor = gateway.resolve(selector);
            if (descriptor.isPresent()) {
                return new Resolution(selector, State.RESOLVABLE, null, descriptor.orElseThrow());
            }
        }
        return new Resolution(selector, State.MISSING, null, null);
    }
}
