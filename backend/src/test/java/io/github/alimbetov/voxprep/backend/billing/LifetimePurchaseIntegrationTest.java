package io.github.alimbetov.voxprep.backend.billing;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.billing.LifetimePurchaseService.PurchaseProof;
import io.github.alimbetov.voxprep.backend.billing.StorePurchaseVerifier.Environment;
import io.github.alimbetov.voxprep.backend.billing.StorePurchaseVerifier.State;
import io.github.alimbetov.voxprep.backend.installation.persistence.InstallationEntity;
import io.github.alimbetov.voxprep.backend.installation.persistence.InstallationRepository;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

/** Real Postgres+Liquibase B8 qualification. No store network or personal data. */
@SpringBootTest(webEnvironment=SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Transactional
class LifetimePurchaseIntegrationTest {
    private static final String PRODUCT = "voxprep_full_unlock";
    @Autowired LifetimePurchaseService service;
    @Autowired PurchaseLedger ledger;
    @Autowired InstallationRepository installations;

    @Test
    void purchaseRestoreIdempotencyAndNoCrossInstallationConflicts() {
        UUID first = installation();
        UUID second = installation();
        var proof = fixture("GOOGLE_PLAY", "GRANTED", "purchase-a");
        assertThat(service.verify(first, request("GOOGLE_PLAY","event-1",proof)).verified()).isTrue();
        assertThat(service.verify(first, request("GOOGLE_PLAY","event-1",proof)).verified()).isTrue();
        assertThat(service.verify(second, request("GOOGLE_PLAY","restore-1",proof)).verified()).isTrue();
        assertThat(ledger.hasEntitlement(first)).isTrue();
        assertThat(ledger.hasEntitlement(second)).isTrue();
        assertThat(service.currentEntitlement(second).verified()).isTrue();
        assertThat(service.currentEntitlement(second).accessLevel()).isEqualTo("FULL");
    }

    @Test
    void sameEventWithDifferentProofIsRejectedRatherThanUnlocking() {
        UUID id = installation();
        service.verify(id,request("APP_STORE","purchase-1",fixture("APP_STORE","GRANTED","first")));
        assertThatThrownBy(() -> service.verify(id,request(
                "APP_STORE","purchase-1",fixture("APP_STORE","GRANTED","different"))))
                .isInstanceOf(PurchaseEventReplayConflictException.class);
    }

    @Test
    void pendingNeverGrantsAndRefundRevokesAllRestoredInstallations() {
        UUID first = installation();
        UUID restored = installation();
        var pending=fixture("GOOGLE_PLAY","PENDING","purchase-b");
        var granted=fixture("GOOGLE_PLAY","GRANTED","purchase-b");
        var revoked=fixture("GOOGLE_PLAY","REVOKED","purchase-b");
        assertThat(service.verify(first,request("GOOGLE_PLAY","pending",pending)).verified()).isFalse();
        assertThat(service.verify(first,request("GOOGLE_PLAY","purchased",granted)).verified()).isTrue();
        assertThat(service.verify(restored,request("GOOGLE_PLAY","restore",granted)).verified()).isTrue();
        assertThat(service.verify(first,request("GOOGLE_PLAY","refund",revoked)).verified()).isFalse();
        assertThat(ledger.hasEntitlement(restored)).isFalse();
        assertThat(service.currentEntitlement(restored).accessLevel()).isEqualTo("FREE");
        // Re-submitting an older GRANTED proof cannot undo a refund tombstone.
        assertThat(service.verify(first,request("GOOGLE_PLAY","stale-replay",granted)).verified()).isFalse();
    }

    @Test
    void verifiedAppleReversalRestoresEntitlementButLateRefundCannotUndoIt() {
        UUID id=installation();
        String proof=fixture("APP_STORE","GRANTED","purchase-c");
        service.verify(id,request("APP_STORE","apple-1",proof));
        String hash=PurchaseDigest.sha256("sim:v1:APP_STORE:purchase-c");
        var base=Instant.parse("2026-11-04T00:00:00Z");
        ledger.applyStoreEvent("APP_STORE",PRODUCT,hash,Environment.SIMULATED,State.REVOKED,base);
        assertThat(ledger.hasEntitlement(id)).isFalse();
        ledger.applyStoreEvent("APP_STORE",PRODUCT,hash,Environment.SIMULATED,
                State.GRANTED,base.plusSeconds(30));
        assertThat(ledger.hasEntitlement(id)).isTrue();
        ledger.applyStoreEvent("APP_STORE",PRODUCT,hash,Environment.SIMULATED,
                State.REVOKED,base.minusSeconds(5));
        assertThat(ledger.hasEntitlement(id)).isTrue();
    }

    @Test
    void storeRevokeOutranksLateClientGrantForTheSameTransaction() {
        UUID id = installation();
        String granted = fixture("GOOGLE_PLAY", "GRANTED", "r5-revoked-after-grant");
        assertThat(service.verify(id, request("GOOGLE_PLAY", "grant-1", granted)).verified()).isTrue();
        String hash = PurchaseDigest.sha256("sim:v1:GOOGLE_PLAY:r5-revoked-after-grant");
        ledger.applyStoreEvent("GOOGLE_PLAY", PRODUCT, hash, Environment.SIMULATED,
                State.REVOKED, Instant.parse("2026-11-04T12:00:00Z"));
        assertThat(service.currentEntitlement(id).accessLevel()).isEqualTo("FREE");
        // Even though an old store proof still decodes to GRANTED, it cannot
        // undo a more recent, independently authenticated store decision.
        assertThat(service.verify(id, request("GOOGLE_PLAY", "stale-after-notification", granted))
                .verified()).isFalse();
        assertThat(service.currentEntitlement(id).accessLevel()).isEqualTo("FREE");
    }

    @Test
    void storePendingOutranksOldClientGrantUntilNewAuthenticatedStoreEvent() {
        UUID id = installation();
        String granted = fixture("APP_STORE", "GRANTED", "r5-store-pending");
        assertThat(service.verify(id, request("APP_STORE", "initial-grant", granted)).verified())
                .isTrue();
        String hash = PurchaseDigest.sha256("sim:v1:APP_STORE:r5-store-pending");
        Instant eventAt = Instant.parse("2026-11-04T12:10:00Z");
        ledger.applyStoreEvent("APP_STORE", PRODUCT, hash, Environment.SIMULATED,
                State.PENDING, eventAt);
        assertThat(service.verify(id, request("APP_STORE", "late-client-grant", granted))
                .verified()).isFalse();
        assertThat(service.currentEntitlement(id).accessLevel()).isEqualTo("FREE");
        ledger.applyStoreEvent("APP_STORE", PRODUCT, hash, Environment.SIMULATED,
                State.GRANTED, eventAt.plusSeconds(1));
        assertThat(service.currentEntitlement(id).accessLevel()).isEqualTo("FULL");
        ledger.applyStoreEvent("APP_STORE", PRODUCT, hash, Environment.SIMULATED,
                State.REVOKED, eventAt.minusSeconds(1));
        assertThat(service.currentEntitlement(id).accessLevel()).isEqualTo("FULL");
    }

    @Test
    void refundBeforeFirstRestoreCreatesTombstoneAndBlocksFreshInstallation() {
        UUID original = installation();
        UUID cleanInstall = installation();
        String proof = fixture("GOOGLE_PLAY", "GRANTED", "refund-before-first-verify");
        String transaction = PurchaseDigest.sha256(
                "sim:v1:GOOGLE_PLAY:refund-before-first-verify");
        Instant refundAt = Instant.parse("2026-11-04T12:30:00Z");

        // Google voided-purchase notification may beat the client's first
        // verify request. This MUST NOT resurrect an already-refunded token.
        ledger.applyStoreEvent("GOOGLE_PLAY", PRODUCT, transaction,
                Environment.SIMULATED, State.REVOKED, refundAt);
        assertThat(service.verify(original, request("GOOGLE_PLAY", "purchase-late", proof))
                .accessLevel()).isEqualTo("FREE");
        assertThat(service.verify(cleanInstall, request("GOOGLE_PLAY", "restore-late", proof))
                .accessLevel()).isEqualTo("FREE");
        assertThat(ledger.hasEntitlement(original)).isFalse();
        assertThat(ledger.hasEntitlement(cleanInstall)).isFalse();

        // A repeated refund and an older (delayed) purchase notification
        // cannot override the tombstone, regardless of delivery order.
        ledger.applyStoreEvent("GOOGLE_PLAY", PRODUCT, transaction,
                Environment.SIMULATED, State.REVOKED, refundAt);
        ledger.applyStoreEvent("GOOGLE_PLAY", PRODUCT, transaction,
                Environment.SIMULATED, State.GRANTED, refundAt.minusSeconds(20));
        assertThat(service.currentEntitlement(cleanInstall).verified()).isFalse();
    }

    @Test
    void duplicateTimestampCannotReverseStoreRefund() {
        UUID id = installation();
        String proof = fixture("APP_STORE", "GRANTED", "same-timestamp-race");
        service.verify(id, request("APP_STORE", "initial", proof));
        String transaction = PurchaseDigest.sha256(
                "sim:v1:APP_STORE:same-timestamp-race");
        Instant at = Instant.parse("2026-11-04T12:40:00Z");
        ledger.applyStoreEvent("APP_STORE", PRODUCT, transaction,
                Environment.SIMULATED, State.REVOKED, at);
        ledger.applyStoreEvent("APP_STORE", PRODUCT, transaction,
                Environment.SIMULATED, State.GRANTED, at);
        assertThat(service.currentEntitlement(id).accessLevel()).isEqualTo("FREE");
        ledger.applyStoreEvent("APP_STORE", PRODUCT, transaction,
                Environment.SIMULATED, State.GRANTED, at.plusSeconds(1));
        assertThat(service.currentEntitlement(id).accessLevel()).isEqualTo("FULL");
    }

    @Test
    void invalidStoreNotificationIdentityNeverWritesPurchaseState() {
        UUID id = installation();
        Instant at = Instant.parse("2026-11-04T13:00:00Z");
        String validHash = PurchaseDigest.sha256("unrelated-refund");
        assertThatThrownBy(() -> ledger.applyStoreEvent("NOT_A_STORE", PRODUCT,
                validHash, Environment.SIMULATED, State.REVOKED, at))
                .isInstanceOf(org.springframework.dao.InvalidDataAccessApiUsageException.class)
                .hasCauseInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> ledger.applyStoreEvent("GOOGLE_PLAY",
                "unrelated_product", validHash, Environment.SIMULATED,
                State.REVOKED, at)).isInstanceOf(org.springframework.dao.InvalidDataAccessApiUsageException.class)
                .hasCauseInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> ledger.applyStoreEvent("GOOGLE_PLAY",
                PRODUCT, "malformed", Environment.SIMULATED,
                State.REVOKED, at)).isInstanceOf(org.springframework.dao.InvalidDataAccessApiUsageException.class)
                .hasCauseInstanceOf(IllegalArgumentException.class);
        assertThat(service.currentEntitlement(id).verified()).isFalse();
    }

    @Test
    void malformedSimulationsNeverGrantRealEntitlement() {
        UUID id=installation();
        assertThatThrownBy(() -> service.verify(id,request(
                "GOOGLE_PLAY","no-proof","sim:v1:APP_STORE:GRANTED:same")))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> service.verify(id,request(
                "GOOGLE_PLAY","no-product","anything")))
                .isInstanceOf(IllegalArgumentException.class);
        assertThat(ledger.hasEntitlement(id)).isFalse();
    }

    private UUID installation() {
        UUID id=UUID.randomUUID();
        installations.saveAndFlush(new InstallationEntity(
                id,PurchaseDigest.sha256(id.toString()),Instant.now()));
        return id;
    }
    private static String fixture(String provider,String state,String transaction) {
        return "sim:v1:"+provider+":"+state+":"+transaction;
    }
    private static PurchaseProof request(String provider,String event,String proof) {
        return new PurchaseProof(provider,PRODUCT,event,proof);
    }
}
