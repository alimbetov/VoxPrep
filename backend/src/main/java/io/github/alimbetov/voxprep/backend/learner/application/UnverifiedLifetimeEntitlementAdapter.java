package io.github.alimbetov.voxprep.backend.learner.application;

import java.util.UUID;
import org.springframework.stereotype.Component;

/**
 * Safe placeholder until B8 has a real, store-verified, persisted purchase domain.
 *
 * <p>Never replace this with an accepting mock in deployment. A production-ready
 * implementation MUST verify purchase status and revocation before granting access.
 */
@Component
public class UnverifiedLifetimeEntitlementAdapter implements VerifiedLifetimeEntitlementPort {

    @Override
    public boolean hasVerifiedLifetimeUnlock(UUID installationId) {
        return false;
    }
}
