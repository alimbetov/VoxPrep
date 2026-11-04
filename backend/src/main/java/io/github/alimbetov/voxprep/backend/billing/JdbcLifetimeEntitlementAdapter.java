package io.github.alimbetov.voxprep.backend.billing;

import io.github.alimbetov.voxprep.backend.learner.application.VerifiedLifetimeEntitlementPort;
import java.util.UUID;
import org.springframework.stereotype.Component;

/** The authoritative, store-verified entitlement for FULL content access. */
@Component
public class JdbcLifetimeEntitlementAdapter implements VerifiedLifetimeEntitlementPort {
    private final PurchaseLedger ledger;
    public JdbcLifetimeEntitlementAdapter(PurchaseLedger ledger) { this.ledger = ledger; }
    @Override
    public boolean hasVerifiedLifetimeUnlock(UUID installationId) {
        return ledger.hasEntitlement(installationId);
    }
}
