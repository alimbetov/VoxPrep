package io.github.alimbetov.voxprep.backend.billing;

import io.github.alimbetov.voxprep.backend.billing.StorePurchaseVerifier.StoreDecision;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

/** Privacy-minimal purchase ledger: only salted-free SHA-256 transaction identities,
 * provider/product/state and UUID installation claims; never persist raw Store proofs.
 * Transaction identifiers/tokens are high entropy, unlike passwords.
 */
@Repository
public class PurchaseLedger {
    private final JdbcTemplate jdbc;
    public PurchaseLedger(JdbcTemplate jdbc) { this.jdbc = Objects.requireNonNull(jdbc); }

    @Transactional
    public boolean record(UUID installationId, String eventId, String semanticHash, StoreDecision decision) {
        var previous = jdbc.query("""
            SELECT semantic_sha256 FROM app.purchase_verify_event
             WHERE installation_id = ? AND event_id = ? FOR UPDATE
            """, (rs,n) -> rs.getString(1), installationId, eventId);
        if (!previous.isEmpty() && !previous.getFirst().equals(semanticHash)) {
            throw new PurchaseEventReplayConflictException();
        }
        if (previous.isEmpty()) {
            jdbc.update("""
                INSERT INTO app.purchase_verify_event (installation_id,event_id,semantic_sha256,recorded_at)
                VALUES (?,?,?,now()) ON CONFLICT (installation_id,event_id) DO NOTHING
                """, installationId, eventId, semanticHash);
            var actuallyStored = jdbc.queryForObject("""
                SELECT semantic_sha256 FROM app.purchase_verify_event
                 WHERE installation_id=? AND event_id=?
                """, String.class, installationId, eventId);
            if (!semanticHash.equals(actuallyStored)) {
                throw new PurchaseEventReplayConflictException();
            }
        }

        var purchaseId = jdbc.queryForObject("""
            INSERT INTO app.store_purchase (id,provider,product_id,transaction_sha256,
                     purchase_state,environment,verified_at,updated_at)
            VALUES (?,?,?,?,?,?,?,now())
            ON CONFLICT (provider,product_id,transaction_sha256) DO UPDATE
               SET purchase_state=excluded.purchase_state,
                   verified_at=excluded.verified_at,
                   environment=excluded.environment,
                   updated_at=now()
            RETURNING id
            """, UUID.class, UUID.randomUUID(), decision.provider(), decision.productId(),
                decision.transactionSha256(), decision.state().name(), decision.environment().name(),
                decision.verifiedAt());
        if (decision.state() == StorePurchaseVerifier.State.GRANTED) {
            jdbc.update("""
                INSERT INTO app.store_purchase_claim (purchase_id,installation_id,claimed_at)
                VALUES (?,?,now()) ON CONFLICT DO NOTHING
                """, purchaseId, installationId);
        }
        return hasEntitlement(installationId);
    }

    @Transactional(readOnly=true)
    public boolean hasEntitlement(UUID installationId) {
        Integer active = jdbc.queryForObject("""
            SELECT COUNT(*) FROM app.store_purchase_claim claim
              JOIN app.store_purchase purchase ON purchase.id=claim.purchase_id
              JOIN app.installation i ON i.installation_id=claim.installation_id
             WHERE claim.installation_id=? AND purchase.purchase_state='GRANTED'
               AND i.status='ACTIVE'
            """, Integer.class, installationId);
        return active != null && active > 0;
    }

    /** Called only after an independently authenticated Store notification or reconciliation. */
    @Transactional
    public void updateState(String provider, String productId, String transactionHash,
                            StorePurchaseVerifier.State state) {
        jdbc.update("""
            UPDATE app.store_purchase SET purchase_state=?, updated_at=now(),
              verified_at=CASE WHEN ?='GRANTED' THEN COALESCE(verified_at,now()) ELSE verified_at END
            WHERE provider=? AND product_id=? AND transaction_sha256=?
            """, state.name(), state.name(), provider, productId, transactionHash);
    }
}
