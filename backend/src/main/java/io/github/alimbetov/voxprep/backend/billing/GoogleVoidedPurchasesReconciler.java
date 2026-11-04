package io.github.alimbetov.voxprep.backend.billing;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import tools.jackson.databind.ObjectMapper;

/**
 * Google Play official Voided Purchases API: authoritative refund/chargeback
 * reconciliation even if RTDN was delayed. Uses only OAuth-scoped Store API.
 * API has a 30-day lookback, so alert if this job fails for an extended time.
 */
@Component
@ConditionalOnProperty(prefix="voxprep.billing",name="mode",havingValue="production")
public class GoogleVoidedPurchasesReconciler {
    private static final Logger log = LoggerFactory.getLogger(GoogleVoidedPurchasesReconciler.class);
    private final GooglePlayStoreVerifier google;
    private final PurchaseLedger ledger;
    private final ObjectMapper json;

    public GoogleVoidedPurchasesReconciler(GooglePlayStoreVerifier google,
                                           PurchaseLedger ledger, ObjectMapper json) {
        this.google=google; this.ledger=ledger; this.json=json;
    }

    @Scheduled(initialDelayString="${voxprep.billing.google.voided-poll-delay-ms:900000}",
               fixedDelayString="${voxprep.billing.google.voided-poll-delay-ms:900000}")
    public void reconcile() {
        try {
            String page = null;
            int scanned=0;
            do {
                String url="https://androidpublisher.googleapis.com/androidpublisher/v3/applications/"
                        + google.packageName() + "/purchases/voidedpurchases?type=0"
                        + "&pageSelection.maxResults=1000"
                        + (page == null ? "" : "&pageSelection.token="
                            + URLEncoder.encode(page, StandardCharsets.UTF_8));
                var response=google.send("GET", url);
                if (response.statusCode() != 200) throw new PurchaseVerificationUnavailableException();
                @SuppressWarnings("unchecked")
                Map<String,Object> body=json.readValue(response.body(),Map.class);
                if (body.get("voidedPurchases") instanceof List<?> items) {
                    for (var raw : items) {
                        if (!(raw instanceof Map<?,?> item)
                                || !(item.get("purchaseToken") instanceof String token)
                                || !(item.get("voidedTimeMillis") instanceof String time)) {
                            continue;
                        }
                        var eventTime=Instant.ofEpochMilli(Long.parseLong(time));
                        ledger.applyStoreEvent("GOOGLE_PLAY",LifetimePurchaseService.PRODUCT_ID,
                                PurchaseDigest.sha256(token),StorePurchaseVerifier.Environment.PRODUCTION,
                                StorePurchaseVerifier.State.REVOKED,eventTime);
                        scanned++;
                    }
                }
                Object pages=body.get("tokenPagination");
                page=pages instanceof Map<?,?> pagination
                        ? (String)pagination.get("nextPageToken") : null;
            } while (page != null && !page.isBlank() && scanned < 20_000);
            if (scanned >= 20_000 && page != null && !page.isBlank()) {
                log.warn("Google Voided Purchases reconciliation pagination cap reached");
            }
        } catch (Exception ex) {
            // Do not log raw Store tokens or provider response bodies.
            log.error("Google Voided Purchases reconciliation failed (check Store credentials, quotas and alerting)");
        }
    }
}
