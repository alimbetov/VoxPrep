package io.github.alimbetov.voxprep.backend.billing;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

import io.github.alimbetov.voxprep.backend.billing.LifetimePurchaseService.PurchaseProof;
import io.github.alimbetov.voxprep.backend.billing.StorePurchaseVerifier.Environment;
import io.github.alimbetov.voxprep.backend.billing.StorePurchaseVerifier.State;
import io.github.alimbetov.voxprep.backend.billing.StorePurchaseVerifier.StoreDecision;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Verify provider/app identity before any durable lifetime access claim. */
class LifetimePurchaseServiceIdentityTest {
    @Test
    void crossProviderResponseCannotGrantPurchase() {
        StorePurchaseVerifier verifier = mock(StorePurchaseVerifier.class);
        PurchaseLedger ledger = mock(PurchaseLedger.class);
        String product = LifetimePurchaseService.PRODUCT_ID;
        when(verifier.verify("GOOGLE_PLAY", product, "proof")).thenReturn(
                new StoreDecision("APP_STORE", product, "a".repeat(64), State.GRANTED,
                        Environment.PRODUCTION, Instant.parse("2026-11-04T00:00:00Z")));
        assertThatThrownBy(() -> new LifetimePurchaseService(verifier, ledger).verify(
                UUID.randomUUID(), new PurchaseProof("GOOGLE_PLAY", product, "event-1", "proof")))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("identity");
        verifyNoInteractions(ledger);
    }

    @Test
    void crossProductResponseCannotGrantPurchase() {
        StorePurchaseVerifier verifier = mock(StorePurchaseVerifier.class);
        PurchaseLedger ledger = mock(PurchaseLedger.class);
        String product = LifetimePurchaseService.PRODUCT_ID;
        when(verifier.verify("APP_STORE", product, "proof")).thenReturn(
                new StoreDecision("APP_STORE", "unrelated_product", "b".repeat(64),
                        State.GRANTED, Environment.PRODUCTION,
                        Instant.parse("2026-11-04T00:00:00Z")));
        assertThatThrownBy(() -> new LifetimePurchaseService(verifier, ledger).verify(
                UUID.randomUUID(), new PurchaseProof("APP_STORE", product, "event-2", "proof")))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("identity");
        verifyNoInteractions(ledger);
    }
}
