package io.github.alimbetov.voxprep.backend.billing;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.core.env.Environment;
import java.util.Arrays;
import org.springframework.stereotype.Component;

/**
 * Prevents external VOXPREP_BILLING_MODE overrides from activating test
 * simulators in a production Spring profile. Starts only with real stores.
 */
@Component
@Profile({"prod", "staging"})
public final class ProductionBillingStartupGuard {
    public ProductionBillingStartupGuard(
            Environment environment,
            @Value("${voxprep.billing.mode:disabled}") String billingMode,
            @Value("${voxprep.billing.google.accept-test-purchases:false}") boolean googleTestMode,
            @Value("${voxprep.billing.apple.environment:PRODUCTION}") String appleEnvironment) {
        boolean productionProfile = Arrays.asList(environment.getActiveProfiles()).contains("prod");
        // A production deployment may start while no Store accounts exist,
        // but disabled billing must fail closed: never accept simulator proofs.
        // Once real billing is enabled, all environment checks remain strict.
        if (!(productionProfile && "disabled".equals(billingMode)
                && !googleTestMode && "PRODUCTION".equals(appleEnvironment))
                && (!"production".equals(billingMode)
                    || (productionProfile && (googleTestMode
                        || !"PRODUCTION".equals(appleEnvironment)))
                    || (!productionProfile && (!googleTestMode
                        || !"SANDBOX".equals(appleEnvironment))))) {
            throw new IllegalStateException(
                    "Staging/prod billing must use real store adapters and their correct store environments");
        }
    }
}
