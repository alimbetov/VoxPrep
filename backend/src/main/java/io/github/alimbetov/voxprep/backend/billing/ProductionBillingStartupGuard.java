package io.github.alimbetov.voxprep.backend.billing;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * Prevents external VOXPREP_BILLING_MODE overrides from activating test
 * simulators in a production Spring profile. Starts only with real stores.
 */
@Component
@Profile("prod")
public final class ProductionBillingStartupGuard {
    public ProductionBillingStartupGuard(
            @Value("${voxprep.billing.mode:disabled}") String billingMode,
            @Value("${voxprep.billing.google.accept-test-purchases:false}") boolean googleTestMode,
            @Value("${voxprep.billing.apple.environment:PRODUCTION}") String appleEnvironment) {
        if (!"production".equals(billingMode) || googleTestMode
                || !"PRODUCTION".equals(appleEnvironment)) {
            throw new IllegalStateException(
                    "Production billing requires verified stores, Google test purchases OFF and Apple PRODUCTION");
        }
    }
}
