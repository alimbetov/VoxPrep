package io.github.alimbetov.voxprep.backend.billing;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

/** Production may boot with billing disabled, never with simulated proof acceptance. */
class ProductionBillingStartupGuardTest {

    @Test
    void prodAllowsOnlyFailClosedDisabledModeWithoutStoreAccounts() {
        var production = new MockEnvironment();
        production.setActiveProfiles("prod");
        assertThatCode(() -> new ProductionBillingStartupGuard(
                production, "disabled", false, "PRODUCTION"))
                .doesNotThrowAnyException();
        assertThatThrownBy(() -> new ProductionBillingStartupGuard(
                production, "disabled", true, "PRODUCTION"))
                .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> new ProductionBillingStartupGuard(
                production, "disabled", false, "SANDBOX"))
                .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> new ProductionBillingStartupGuard(
                production, "simulated", false, "PRODUCTION"))
                .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> new ProductionBillingStartupGuard(
                production, "production", true, "SANDBOX"))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void stagingStillRequiresRealStoreSandboxCredentials() {
        var staging = new MockEnvironment();
        staging.setActiveProfiles("staging");
        assertThatThrownBy(() -> new ProductionBillingStartupGuard(
                staging, "disabled", false, "PRODUCTION"))
                .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> new ProductionBillingStartupGuard(
                staging, "simulated", true, "SANDBOX"))
                .isInstanceOf(IllegalStateException.class);
        assertThatCode(() -> new ProductionBillingStartupGuard(
                staging, "production", true, "SANDBOX"))
                .doesNotThrowAnyException();
    }
}
