package io.github.alimbetov.voxprep.backend.billing;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/** Fail closed if deployment doesn't explicitly select a real Store configuration. */
@Component
@ConditionalOnProperty(prefix="voxprep.billing",name="mode",havingValue="disabled",matchIfMissing=true)
public class DisabledStorePurchaseVerifier implements StorePurchaseVerifier {
    @Override
    public StoreDecision verify(String provider, String productId, String verificationData) {
        throw new PurchaseVerificationUnavailableException();
    }
}
