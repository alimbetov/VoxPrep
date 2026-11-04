package io.github.alimbetov.voxprep.backend.billing;

import io.github.alimbetov.voxprep.backend.billing.StorePurchaseVerifier.StoreDecision;
import java.time.Instant;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Service;

/** Does not hold a database transaction open during remote Store API calls. */
@Service
public class LifetimePurchaseService {
    public static final String PRODUCT_ID = "voxprep_full_unlock";
    private final StorePurchaseVerifier verifier;
    private final PurchaseLedger ledger;

    public LifetimePurchaseService(StorePurchaseVerifier verifier, PurchaseLedger ledger) {
        this.verifier = Objects.requireNonNull(verifier);
        this.ledger = Objects.requireNonNull(ledger);
    }

    public VerificationResult verify(UUID installationId, PurchaseProof proof) {
        Objects.requireNonNull(installationId);
        if (proof == null || !Set.of("GOOGLE_PLAY", "APP_STORE").contains(proof.provider())
                || !PRODUCT_ID.equals(proof.productId())
                || proof.purchaseEventId() == null
                || !proof.purchaseEventId().matches("[a-zA-Z0-9._:-]{1,160}")
                || proof.verificationData() == null || proof.verificationData().isBlank()
                || proof.verificationData().length() > 16384) {
            throw new IllegalArgumentException("Invalid purchase verification request");
        }

        String semanticHash = PurchaseDigest.sha256(proof.provider() + "\n" + proof.productId()
                + "\n" + proof.verificationData());
        // Only a cryptographically authenticated store response (or DEV simulator)
        // can become a GRANTED ledger entry; the Flutter Boolean is never trusted.
        StoreDecision decision = verifier.verify(proof.provider(), proof.productId(),
                proof.verificationData());
        // Provider adapter mistakes must fail closed before any durable claim.
        if (decision == null || !proof.provider().equals(decision.provider())
                || !PRODUCT_ID.equals(decision.productId())) {
            throw new IllegalArgumentException("Verified store identity does not match request");
        }
        ledger.record(installationId, proof.purchaseEventId(), semanticHash, decision);
        // An independently authenticated store event may already have superseded
        // this proof. Return the authoritative ledger state, never just the
        // verifier's possibly stale GRANTED response.
        return currentEntitlement(installationId);
    }

    public VerificationResult currentEntitlement(UUID installationId) {
        return ledger.verifiedAt(Objects.requireNonNull(installationId))
                .map(verifiedAt -> new VerificationResult(true, "FULL", verifiedAt))
                .orElseGet(() -> new VerificationResult(false, "FREE", null));
    }

    public record PurchaseProof(String provider, String productId, String purchaseEventId,
                                String verificationData) {}
    public record VerificationResult(boolean verified, String accessLevel, Instant verifiedAt) {}
}
