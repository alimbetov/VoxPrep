package io.github.alimbetov.voxprep.backend.billing;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;
import tools.jackson.databind.ObjectMapper;

/**
 * Authenticated Google Pub/Sub RTDN push transport.
 * The signed Pub/Sub JWT is checked before accepting any untrusted JSON.
 * For purchased/canceled one-time products, Google Developer API is the
 * authority; the notification body alone cannot grant FULL.
 */
@RestController
@ConditionalOnProperty(prefix = "voxprep.billing", name = "mode", havingValue = "production")
public final class GooglePlayNotificationController {
    private final GooglePubSubPushAuthenticator authentication;
    private final GooglePlayStoreVerifier google;
    private final PurchaseLedger ledger;
    private final ObjectMapper json;

    public GooglePlayNotificationController(GooglePubSubPushAuthenticator authentication,
            GooglePlayStoreVerifier google, PurchaseLedger ledger, ObjectMapper json) {
        this.authentication = authentication;
        this.google = google;
        this.ledger = ledger;
        this.json = json;
    }

    @PostMapping("/api/v1/store/notifications/google")
    public ResponseEntity<Void> receive(
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @RequestBody(required = false) String body) {
        if (!authentication.authenticated(authorization)) {
            return ResponseEntity.status(401).build();
        }
        if (body == null || body.isBlank() || body.length() > 131_072) {
            return ResponseEntity.badRequest().build();
        }
        final Map<?, ?> notice;
        try {
            Map<?, ?> envelope = json.readValue(body, Map.class);
            if (!(envelope.get("message") instanceof Map<?, ?> message)
                    || !(message.get("data") instanceof String encoded)
                    || encoded.length() > 65_536) {
                return ResponseEntity.badRequest().build();
            }
            byte[] bytes = Base64.getDecoder().decode(encoded);
            notice = json.readValue(new String(bytes, StandardCharsets.UTF_8), Map.class);
        } catch (Exception malformed) {
            return ResponseEntity.badRequest().build();
        }

        if (!google.packageName().equals(notice.get("packageName"))) {
            return ResponseEntity.badRequest().build();
        }

        final Instant eventAt;
        try {
            eventAt = Instant.ofEpochMilli(Long.parseLong(String.valueOf(notice.get("eventTimeMillis"))));
        } catch (RuntimeException invalidTime) {
            return ResponseEntity.badRequest().build();
        }

        try {
            if (notice.get("oneTimeProductNotification") instanceof Map<?, ?> event) {
                if (!LifetimePurchaseService.PRODUCT_ID.equals(event.get("sku"))) {
                    return ResponseEntity.ok().build(); // Other in-app products are out of scope.
                }
                if (!(event.get("purchaseToken") instanceof String token)
                        || token.isBlank() || token.length() > 8192) {
                    return ResponseEntity.badRequest().build();
                }
                int kind = Integer.parseInt(String.valueOf(event.get("notificationType")));
                if (kind != 1 && kind != 2) return ResponseEntity.ok().build();
                var decision = google.verify(LifetimePurchaseService.PRODUCT_ID, token);
                if (!"GOOGLE_PLAY".equals(decision.provider())
                        || !LifetimePurchaseService.PRODUCT_ID.equals(decision.productId())) {
                    return ResponseEntity.status(503).build();
                }
                ledger.applyStoreEvent("GOOGLE_PLAY", LifetimePurchaseService.PRODUCT_ID,
                        decision.transactionSha256(), decision.environment(), decision.state(), eventAt);
            } else if (notice.get("voidedPurchaseNotification") instanceof Map<?, ?> voided) {
                // Only a full refund for a one-time product revokes this SKU.
                // Partial refunds are not authoritative for an entire lifetime right.
                int productType = Integer.parseInt(String.valueOf(voided.get("productType")));
                int refundType = Integer.parseInt(String.valueOf(voided.get("refundType")));
                if (productType == 2 && refundType == 1
                        && voided.get("purchaseToken") instanceof String token
                        && !token.isBlank() && token.length() <= 8192) {
                    ledger.applyStoreEvent("GOOGLE_PLAY", LifetimePurchaseService.PRODUCT_ID,
                            PurchaseDigest.sha256(token), StorePurchaseVerifier.Environment.PRODUCTION,
                            StorePurchaseVerifier.State.REVOKED, eventAt);
                }
            }
            // Pub/Sub 2xx ACK, including other unrelated notification types.
            return ResponseEntity.ok().build();
        } catch (PurchaseVerificationUnavailableException externalStoreFailure) {
            // Pub/Sub retries non-2xx; never acknowledge a failed Store API check.
            return ResponseEntity.status(503).build();
        } catch (RuntimeException malformedOrTransient) {
            // Invalid payloads fail closed; never record a grant from bad input.
            return ResponseEntity.badRequest().build();
        }
    }
}
