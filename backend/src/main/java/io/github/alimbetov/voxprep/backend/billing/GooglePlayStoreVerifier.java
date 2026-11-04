package io.github.alimbetov.voxprep.backend.billing;

import com.google.auth.oauth2.GoogleCredentials;
import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import tools.jackson.databind.ObjectMapper;

/** Google Play purchases.productsv2.getproductpurchasev2 + products.acknowledge. */
public class GooglePlayStoreVerifier {
    private static final String BASE =
            "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/";
    private final String packageName;
    private final GoogleCredentials credentials;
    private final HttpClient http;
    private final ObjectMapper json;
    private final boolean acceptTestPurchases;

    public GooglePlayStoreVerifier(String packageName, GoogleCredentials credentials,
                                   ObjectMapper json, boolean acceptTestPurchases) {
        if (packageName == null || !packageName.matches("[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z][A-Za-z0-9_]*)+")) {
            throw new IllegalArgumentException("Configured Google Play package name is invalid");
        }
        this.packageName = packageName;
        this.credentials = Objects.requireNonNull(credentials);
        this.json = Objects.requireNonNull(json);
        this.acceptTestPurchases = acceptTestPurchases;
        this.http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(4)).build();
    }

    public StorePurchaseVerifier.StoreDecision verify(String product, String token) {
        if (token == null || token.length() > 8192 || token.isBlank()) {
            throw new IllegalArgumentException("Invalid Google Play purchase token");
        }
        String url = BASE + packageName + "/purchases/productsv2/tokens/" + enc(token);
        var response = send("GET", url);
        if (response.statusCode() == 404 || response.statusCode() == 400) {
            return decision(product, token, StorePurchaseVerifier.State.REVOKED, null);
        }
        if (response.statusCode() != 200) throw new PurchaseVerificationUnavailableException();
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> body = json.readValue(response.body(), Map.class);
            Object lines = body.get("productLineItem");
            if (!(lines instanceof List<?> lineItems) || lineItems.size() != 1
                    || !(lineItems.getFirst() instanceof Map<?, ?> item)
                    || !product.equals(item.get("productId"))) {
                return decision(product, token, StorePurchaseVerifier.State.REVOKED, null);
            }
            // Lifetime unlock is NON_CONSUMABLE: a consumed purchase token
            // must not be reused to grant perpetual access.
            if (item.get("productOfferDetails") instanceof Map<?, ?> details) {
                // A lifetime unlock must not be a consumed or rental item.
                // A fully refunded single-quantity product is also ineligible.
                Object refundable = details.get("refundableQuantity");
                if ("CONSUMPTION_STATE_CONSUMED".equals(details.get("consumptionState"))
                        || details.get("rentOfferDetails") != null
                        || (refundable instanceof Number count && count.intValue() == 0)) {
                    return decision(product, token, StorePurchaseVerifier.State.REVOKED, null);
                }
            }
            if (body.get("testPurchaseContext") != null && !acceptTestPurchases) {
                return decision(product, token, StorePurchaseVerifier.State.REVOKED, null);
            }
            if (!(body.get("purchaseStateContext") instanceof Map<?, ?> ctx)) {
                throw new PurchaseVerificationUnavailableException();
            }
            var state = String.valueOf(ctx.get("purchaseState"));
            if ("PENDING".equals(state)) {
                return decision(product, token, StorePurchaseVerifier.State.PENDING, null);
            }
            if ("CANCELLED".equals(state)) {
                return decision(product, token, StorePurchaseVerifier.State.REVOKED, null);
            }
            if (!"PURCHASED".equals(state)
                    || !(body.get("purchaseCompletionTime") instanceof String purchasedAt)) {
                throw new PurchaseVerificationUnavailableException();
            }
            // For one-time NON_CONSUMABLE product, acknowledge without consuming.
            if (!"ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED".equals(body.get("acknowledgementState"))) {
                var acknowledged = send("POST", BASE + packageName
                        + "/purchases/products/" + enc(product)
                        + "/tokens/" + enc(token) + ":acknowledge");
                if (acknowledged.statusCode() != 200 && acknowledged.statusCode() != 204
                        && acknowledged.statusCode() != 409) {
                    throw new PurchaseVerificationUnavailableException();
                }
            }
            return new StorePurchaseVerifier.StoreDecision("GOOGLE_PLAY", product,
                    PurchaseDigest.sha256(token), StorePurchaseVerifier.State.GRANTED,
                    body.get("testPurchaseContext") != null
                            ? StorePurchaseVerifier.Environment.SANDBOX
                            : StorePurchaseVerifier.Environment.PRODUCTION,
                    Instant.parse(purchasedAt));
        } catch (PurchaseVerificationUnavailableException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new PurchaseVerificationUnavailableException();
        }
    }

    public HttpResponse<String> send(String method, String url) {
        try {
            synchronized (credentials) { credentials.refreshIfExpired(); }
            String bearer = credentials.getAccessToken().getTokenValue();
            var request = HttpRequest.newBuilder(URI.create(url))
                    .timeout(Duration.ofSeconds(10))
                    .header("Authorization", "Bearer " + bearer)
                    .header("Accept", "application/json");
            if ("POST".equals(method)) request.header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString("{}"));
            else request.GET();
            return http.send(request.build(), HttpResponse.BodyHandlers.ofString());
        } catch (Exception ex) {
            throw new PurchaseVerificationUnavailableException();
        }
    }

    private StorePurchaseVerifier.StoreDecision decision(
            String product, String token, StorePurchaseVerifier.State state, Instant verifiedAt) {
        return new StorePurchaseVerifier.StoreDecision("GOOGLE_PLAY", product,
                PurchaseDigest.sha256(token), state,
                StorePurchaseVerifier.Environment.PRODUCTION, verifiedAt);
    }

    private static String enc(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    public String packageName() { return packageName; }
}
