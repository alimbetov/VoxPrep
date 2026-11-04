package io.github.alimbetov.voxprep.backend.billing;

import java.time.Instant;
import java.util.regex.Pattern;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/** DEV/TEST ONLY: deliberately deterministic, never accepted in production. */
@Component
@ConditionalOnProperty(prefix="voxprep.billing", name="mode", havingValue="simulated")
public class SimulatedStorePurchaseVerifier implements StorePurchaseVerifier {
    private static final Pattern FIXTURE = Pattern.compile(
            "sim:v1:(GOOGLE_PLAY|APP_STORE):(GRANTED|PENDING|REVOKED):([A-Za-z0-9_-]{1,80})");

    @Override
    public StoreDecision verify(String provider, String productId, String data) {
        var match = FIXTURE.matcher(data);
        if (!match.matches() || !match.group(1).equals(provider)
                || !LifetimePurchaseService.PRODUCT_ID.equals(productId)) {
            throw new IllegalArgumentException("Invalid DEV/TEST simulator purchase");
        }
        State state = State.valueOf(match.group(2));
        String transactionHash = PurchaseDigest.sha256("sim:v1:" + provider + ":" + match.group(3));
        return new StoreDecision(provider, productId, transactionHash, state,
                Environment.SIMULATED, state == State.GRANTED ? Instant.now() : null);
    }
}
