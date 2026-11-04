package io.github.alimbetov.voxprep.backend.billing;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import io.github.alimbetov.voxprep.backend.billing.StorePurchaseVerifier.Environment;
import io.github.alimbetov.voxprep.backend.billing.StorePurchaseVerifier.State;
import io.github.alimbetov.voxprep.backend.billing.StorePurchaseVerifier.StoreDecision;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.ResponseEntity;
import tools.jackson.databind.ObjectMapper;

/** Real Pub/Sub envelope JSON; only the Google JWT and Store HTTP are mocked. */
class GooglePlayNotificationControllerTest {
    private static final String APP = "io.github.voxprep.app";
    private static final String PRODUCT = LifetimePurchaseService.PRODUCT_ID;
    private final GooglePubSubPushAuthenticator auth = mock(GooglePubSubPushAuthenticator.class);
    private final GooglePlayStoreVerifier google = mock(GooglePlayStoreVerifier.class);
    private final PurchaseLedger ledger = mock(PurchaseLedger.class);
    private final GooglePlayNotificationController controller =
            new GooglePlayNotificationController(auth, google, ledger, new ObjectMapper());

    @BeforeEach
    void setup() {
        when(auth.authenticated("Bearer valid")).thenReturn(true);
        when(google.packageName()).thenReturn(APP);
    }

    @Test
    void rejectsUnsignedPubSubPushBeforeParsingOrStoreAccess() {
        ResponseEntity<Void> response = controller.receive(null, "not-json");
        assertThat(response.getStatusCode().value()).isEqualTo(401);
        verifyNoInteractions(google, ledger);
    }

    @Test
    void rejectsAnotherAppEvenWithAuthenticatedPushJwt() {
        var payload = message("""
                {"packageName":"malicious.example","eventTimeMillis":"%d",
                 "oneTimeProductNotification":{"sku":"voxprep_full_unlock",
                   "notificationType":1,"purchaseToken":"secret"}}
                """.formatted(Instant.now().toEpochMilli()));
        assertThat(controller.receive("Bearer valid", payload).getStatusCode().value()).isEqualTo(400);
        verify(google, never()).verify(anyString(), anyString());
        verifyNoInteractions(ledger);
    }

    @Test
    void purchasedRtdnRechecksGoogleBeforeRecordingGrant() {
        var time = Instant.now();
        var payload = oneTime(time, 1, PRODUCT);
        when(google.verify(PRODUCT, "secret")).thenReturn(decision(State.GRANTED));
        assertThat(controller.receive("Bearer valid", payload).getStatusCode().value()).isEqualTo(200);
        verify(google).verify(PRODUCT, "secret");
        verify(ledger).applyStoreEvent(eq("GOOGLE_PLAY"), eq(PRODUCT), eq("a".repeat(64)),
                eq(Environment.PRODUCTION), eq(State.GRANTED), any(Instant.class));
    }

    @Test
    void pendingGoogleStateNeverGrantsDespitePurchasedNotification() {
        when(google.verify(PRODUCT, "secret")).thenReturn(decision(State.PENDING));
        assertThat(controller.receive("Bearer valid", oneTime(Instant.now(), 1, PRODUCT))
                .getStatusCode().value()).isEqualTo(200);
        verify(ledger).applyStoreEvent(eq("GOOGLE_PLAY"), eq(PRODUCT), anyString(),
                eq(Environment.PRODUCTION), eq(State.PENDING), any(Instant.class));
        verify(ledger, never()).applyStoreEvent(anyString(), anyString(), anyString(),
                any(), eq(State.GRANTED), any());
    }

    @Test
    void failedDeveloperApiLeavesNotificationUnacknowledgedForRetry() {
        when(google.verify(PRODUCT, "secret"))
                .thenThrow(new PurchaseVerificationUnavailableException());
        assertThat(controller.receive("Bearer valid", oneTime(Instant.now(), 1, PRODUCT))
                .getStatusCode().value()).isEqualTo(503);
        verifyNoInteractions(ledger);
    }

    @Test
    void ignoresOtherProductNotificationsWithoutTouchingPurchaseLedger() {
        assertThat(controller.receive("Bearer valid", oneTime(Instant.now(), 1, "unrelated"))
                .getStatusCode().value()).isEqualTo(200);
        verify(google, never()).verify(anyString(), anyString());
        verifyNoInteractions(ledger);
    }

    @Test
    void refundRtdnCannotRevokeWithoutIndependentStoreConfirmation() {
        var payload = message("""
                {"packageName":"%s","eventTimeMillis":"%d",
                  "voidedPurchaseNotification":{
                    "productType":2,"refundType":1,"purchaseToken":"secret"}}
                """.formatted(APP, Instant.now().toEpochMilli()));
        when(google.verify(PRODUCT, "secret")).thenReturn(decision(State.GRANTED));
        assertThat(controller.receive("Bearer valid", payload).getStatusCode().value()).isEqualTo(503);
        verifyNoInteractions(ledger);
        when(google.verify(PRODUCT, "secret")).thenReturn(decision(State.REVOKED));
        assertThat(controller.receive("Bearer valid", payload).getStatusCode().value()).isEqualTo(200);
        verify(ledger).applyStoreEvent(eq("GOOGLE_PLAY"), eq(PRODUCT), eq("a".repeat(64)),
                eq(Environment.PRODUCTION), eq(State.REVOKED), any(Instant.class));
    }

    @Test
    void futureDatedRtdnCannotFreezeOutLaterStoreRevocations() {
        assertThat(controller.receive("Bearer valid",
                oneTime(Instant.now().plusSeconds(3600), 1, PRODUCT))
                .getStatusCode().value()).isEqualTo(400);
        verifyNoInteractions(ledger);
    }

    private static StoreDecision decision(State state) {
        return new StoreDecision("GOOGLE_PLAY", PRODUCT, "a".repeat(64), state,
                Environment.PRODUCTION, state == State.GRANTED ? Instant.now() : null);
    }

    private static String oneTime(Instant eventAt, int type, String product) {
        return message("""
                {"packageName":"%s","eventTimeMillis":"%d",
                  "oneTimeProductNotification":{"sku":"%s",
                    "notificationType":%d,"purchaseToken":"secret"}}
                """.formatted(APP, eventAt.toEpochMilli(), product, type));
    }

    private static String message(String developerNotificationJson) {
        return """
                {"message":{"data":"%s","messageId":"r5-test-message"}}
                """.formatted(Base64.getEncoder().encodeToString(
                developerNotificationJson.getBytes(StandardCharsets.UTF_8)));
    }
}
