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
