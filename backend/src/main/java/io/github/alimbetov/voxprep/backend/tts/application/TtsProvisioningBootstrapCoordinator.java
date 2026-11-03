package io.github.alimbetov.voxprep.backend.tts.application;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.locks.ReentrantLock;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

@Component
public class TtsProvisioningBootstrapCoordinator implements ApplicationRunner {

    private final TtsProvisioningProperties properties;
    private final TtsModelProvisioningService provisioningService;
    private final TtsModelMaterializationService materializationService;
    private final ReentrantLock processLock = new ReentrantLock();

    public TtsProvisioningBootstrapCoordinator(
            TtsProvisioningProperties properties,
            TtsModelProvisioningService provisioningService,
            TtsModelMaterializationService materializationService) {
        this.properties = Objects.requireNonNull(properties, "properties");
        this.provisioningService = Objects.requireNonNull(provisioningService, "provisioningService");
        this.materializationService = Objects.requireNonNull(materializationService, "materializationService");
    }

    @Override
    public void run(ApplicationArguments args) {
        provisionConfiguredSeeds();
    }

    public ProvisioningReport provisionConfiguredSeeds() {
        if (properties.getMode() == TtsProvisioningMode.DISABLED) {
            return new ProvisioningReport(0, 0, List.of());
        }

        processLock.lock();
        try {
            int present = 0;
            int materialized = 0;
            List<String> missing = new ArrayList<>();

            for (TtsProvisioningProperties.Seed seed : properties.getSeeds()) {
                TtsModelSelector selector = seed.selector();
                TtsModelProvisioningService.Resolution resolution = provisioningService.resolve(selector);
                switch (resolution.state()) {
                    case PRESENT -> present++;
                    case RESOLVABLE -> {
                        materializationService.materialize(selector, resolution.descriptor());
                        materialized++;
                    }
                    case MISSING -> missing.add(selector.modelCode());
                }
            }

            if (properties.getMode() == TtsProvisioningMode.STRICT && !missing.isEmpty()) {
                throw new TtsProvisioningException("Missing required TTS models: " + String.join(", ", missing));
            }
            return new ProvisioningReport(present, materialized, List.copyOf(missing));
        } finally {
            processLock.unlock();
        }
    }

    public record ProvisioningReport(int present, int materialized, List<String> missing) {
        public ProvisioningReport {
            missing = List.copyOf(Objects.requireNonNull(missing, "missing"));
        }
    }

    public static class TtsProvisioningException extends RuntimeException {
        public TtsProvisioningException(String message) {
            super(message);
        }
    }
}
