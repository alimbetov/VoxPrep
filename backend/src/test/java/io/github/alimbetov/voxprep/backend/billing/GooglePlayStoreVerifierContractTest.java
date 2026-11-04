package io.github.alimbetov.voxprep.backend.billing;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

import com.google.auth.oauth2.GoogleCredentials;
import java.net.http.HttpResponse;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

/**
 * Fake transport, real Google ProductPurchaseV2 JSON parsing and state policy.
 * These tests do not imply sandbox Store integration acceptance.
 */
class GooglePlayStoreVerifierContractTest {
    private static final String PRODUCT = LifetimePurchaseService.PRODUCT_ID;
    private static final String PACKAGE_NAME = "io.github.voxprep.app";

    @Test
    void realV2PurchasedContractAcknowledgesAndGrants() {
        var transport = verifier(response("PURCHASED", false, false, false), true);
        var decision = transport.verify(PRODUCT, "purchase-token");
        assertThat(decision.state()).isEqualTo(StorePurchaseVerifier.State.GRANTED);
        assertThat(decision.environment()).isEqualTo(StorePurchaseVerifier.Environment.PRODUCTION);
        assertThat(transport.requests).hasSize(2);
        assertThat(transport.requests.get(0)).startsWith("GET ");
        assertThat(transport.requests.get(1)).contains("/purchases/products/" + PRODUCT + "/tokens/");
    }

    @Test
    void consumedProductIsNotAcceptableAsLifetimeUnlock() {
        var transport = verifier(response("PURCHASED", true, false, false), true);
        var decision = transport.verify(PRODUCT, "purchase-token");
        assertThat(decision.state()).isEqualTo(StorePurchaseVerifier.State.REVOKED);
        assertThat(transport.requests).hasSize(1);
    }

    @Test
    void pendingPurchaseCannotGrantOrBeAcknowledged() {
        var transport = verifier(response("PENDING", false, false, false), true);
        assertThat(transport.verify(PRODUCT, "purchase-token").state())
                .isEqualTo(StorePurchaseVerifier.State.PENDING);
        assertThat(transport.requests).hasSize(1);
    }

    @Test
    void testPurchaseIsRejectedOutsideLicensedSandbox() {
        var transport = verifier(response("PURCHASED", false, true, true), false);
        assertThat(transport.verify(PRODUCT, "purchase-token").state())
                .isEqualTo(StorePurchaseVerifier.State.REVOKED);
        assertThat(transport.requests).hasSize(1);
    }

    @Test
    void acknowledgedPurchaseDoesNotAcknowledgeAgain() {
        var transport = verifier(response("PURCHASED", false, false, true), true);
        assertThat(transport.verify(PRODUCT, "purchase-token").state())
                .isEqualTo(StorePurchaseVerifier.State.GRANTED);
        assertThat(transport.requests).hasSize(1);
    }

    @SuppressWarnings("unchecked")
    private static HttpResponse<String> responseBody(String body) {
        HttpResponse<String> response = mock(HttpResponse.class);
        when(response.statusCode()).thenReturn(200);
        when(response.body()).thenReturn(body);
        return response;
    }

    private static FakeTransport verifier(String body, boolean acceptTest) {
        return new FakeTransport(body, acceptTest);
    }

    private static String response(String state, boolean consumed, boolean test, boolean acknowledged) {
        return """
                {
                  "productLineItem": [{
                    "productId": "voxprep_full_unlock",
                    "productOfferDetails": {
                      "consumptionState": "%s"
                    }
                  }],
                  "purchaseStateContext": {"purchaseState": "%s"},
                  "purchaseCompletionTime": "2026-11-04T12:00:00Z",
                  "acknowledgementState": "%s"
                  %s
                }
                """.formatted(
                consumed ? "CONSUMPTION_STATE_CONSUMED" : "CONSUMPTION_STATE_YET_TO_BE_CONSUMED",
                state,
                acknowledged ? "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED" : "ACKNOWLEDGEMENT_STATE_PENDING",
                test ? ", \"testPurchaseContext\": {\"fopType\": \"TEST\"}" : "");
    }

    private static final class FakeTransport extends GooglePlayStoreVerifier {
        private final String jsonResponse;
        final List<String> requests = new ArrayList<>();

        FakeTransport(String jsonResponse, boolean acceptTest) {
            super(PACKAGE_NAME, mock(GoogleCredentials.class), new ObjectMapper(), acceptTest);
            this.jsonResponse = jsonResponse;
        }

        @Override
        public HttpResponse<String> send(String method, String url) {
            requests.add(method + " " + url);
            return responseBody("GET".equals(method) ? jsonResponse : "{}");
        }
    }
}
