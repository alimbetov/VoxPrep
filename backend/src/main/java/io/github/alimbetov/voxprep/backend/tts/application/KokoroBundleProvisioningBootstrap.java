package io.github.alimbetov.voxprep.backend.tts.application;

import java.util.HashSet;
import java.util.Objects;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

/** Explicit startup provisioning only; default disabled in every environment. */
@Component
@Order(50)
public class KokoroBundleProvisioningBootstrap implements ApplicationRunner {
    private final KokoroProvisioningProperties properties;
    private final KokoroBundleProvisioningService bundles;

    public KokoroBundleProvisioningBootstrap(
            KokoroProvisioningProperties properties,
            KokoroBundleProvisioningService bundles) {
        this.properties = Objects.requireNonNull(properties, "properties");
        this.bundles = Objects.requireNonNull(bundles, "bundles");
    }

    @Override
    public void run(ApplicationArguments args) {
        provisionConfiguredBundles();
    }

    public int provisionConfiguredBundles() {
        if (!properties.isEnabled()) {
            return 0;
        }
        if (properties.getBundles() == null || properties.getBundles().isEmpty()) {
            throw new IllegalStateException(
                    "Kokoro provisioning enabled but no pinned bundles are configured");
        }
        int provisioned = 0;
        var codes = new HashSet<String>();
        for (var bundle : properties.getBundles()) {
            if (bundle == null || !codes.add(bundle.getModelCode())) {
                throw new IllegalArgumentException("Duplicate or null Kokoro model bundle");
            }
            bundles.provision(bundle);
            provisioned++;
        }
        return provisioned;
    }
}
