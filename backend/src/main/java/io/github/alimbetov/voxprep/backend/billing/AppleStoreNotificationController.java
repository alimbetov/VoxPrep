package io.github.alimbetov.voxprep.backend.billing;

import com.apple.itunes.storekit.verification.VerificationException;
import java.util.Map;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * Public transport, signed-content authentication: ONLY Apple's verified JWS
 * can mutate purchase state. Configure App Store Connect Notifications V2 URL.
 */
@RestController
@ConditionalOnProperty(prefix="voxprep.billing",name="mode",havingValue="production")
public class AppleStoreNotificationController {

    private final AppleStoreVerifier apple;
    private final PurchaseLedger ledger;

    public AppleStoreNotificationController(AppleStoreVerifier apple, PurchaseLedger ledger) {
        this.apple=apple;
        this.ledger=ledger;
    }

    @PostMapping("/api/v1/store/notifications/apple")
    public ResponseEntity<Void> receive(@RequestBody Map<String, String> payload)
            throws VerificationException {
        String signedPayload = payload == null ? null : payload.get("signedPayload");
        if (signedPayload == null || signedPayload.isBlank() || signedPayload.length() > 200_000) {
            return ResponseEntity.badRequest().build();
        }
        var event=apple.verifyNotification(signedPayload);
        var next = switch (event.notificationType()) {
            case "REFUND", "REVOKE" -> StorePurchaseVerifier.State.REVOKED;
            case "REFUND_REVERSED" -> StorePurchaseVerifier.State.GRANTED;
            default -> null;
        };
        if (next != null) {
            var purchase=event.purchase();
            ledger.applyStoreEvent("APP_STORE", purchase.productId(),
                    purchase.transactionSha256(), purchase.environment(), next, event.signedAt());
        }
        return ResponseEntity.ok().build();
    }

    @ExceptionHandler({VerificationException.class, IllegalArgumentException.class})
    ResponseEntity<Void> invalidSignature(Exception ignored) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
    }
}
