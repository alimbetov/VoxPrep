package io.github.alimbetov.voxprep.backend.billing;

import java.time.Instant;

/** Provider response must be authenticated by Google/Apple or deterministic DEV simulation. */
public interface StorePurchaseVerifier {
    StoreDecision verify(String provider, String productId, String verificationData);

    record StoreDecision(String provider, String productId, String transactionSha256,
                         State state, Environment environment, Instant verifiedAt) {
        public StoreDecision {
            if (transactionSha256 == null || !transactionSha256.matches("[0-9a-f]{64}")) {
                throw new IllegalArgumentException("transaction identity must be SHA-256");
            }
            if (state == State.GRANTED && verifiedAt == null) {
                throw new IllegalArgumentException("granted purchase needs verifiedAt");
            }
        }
    }

    enum State { GRANTED, PENDING, REVOKED }
    enum Environment { PRODUCTION, SANDBOX, SIMULATED }
}
