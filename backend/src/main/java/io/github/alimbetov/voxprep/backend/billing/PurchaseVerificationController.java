package io.github.alimbetov.voxprep.backend.billing;

import io.github.alimbetov.voxprep.backend.installation.security.InstallationPrincipal;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/** Same 4 request keys and 3 response keys required by existing production Flutter. */
@RestController
public class PurchaseVerificationController {
    private final LifetimePurchaseService service;
    public PurchaseVerificationController(LifetimePurchaseService service) { this.service = service; }

    @PostMapping("/api/v1/purchases/verify")
    public ResponseEntity<LifetimePurchaseService.VerificationResult> verify(
            @AuthenticationPrincipal InstallationPrincipal principal,
            @Valid @RequestBody Request request) {
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        var result = service.verify(principal.installationId(),
                new LifetimePurchaseService.PurchaseProof(
                        request.provider(), request.productId(),
                        request.purchaseEventId(), request.verificationData()));
        return ResponseEntity.ok().header("Cache-Control", "no-store").body(result);
    }

    @GetMapping("/api/v1/purchases/entitlement")
    public ResponseEntity<LifetimePurchaseService.VerificationResult> entitlement(
            @AuthenticationPrincipal InstallationPrincipal principal) {
        if (principal == null) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        return ResponseEntity.ok().header("Cache-Control", "no-store")
                .body(service.currentEntitlement(principal.installationId()));
    }

    public record Request(@NotBlank String provider, @NotBlank String productId,
                          @NotBlank String purchaseEventId,
                          @NotBlank @Size(max=16384) String verificationData) {}

    @ExceptionHandler(IllegalArgumentException.class)
    ResponseEntity<Map<String, String>> badRequest(IllegalArgumentException ignored) {
        return ResponseEntity.badRequest().body(Map.of("code", "PURCHASE_PROOF_INVALID"));
    }

    @ExceptionHandler(PurchaseEventReplayConflictException.class)
    ResponseEntity<Map<String, String>> replay(PurchaseEventReplayConflictException ignored) {
        return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of("code", "PURCHASE_EVENT_REPLAY_CONFLICT"));
    }

    @ExceptionHandler(PurchaseVerificationUnavailableException.class)
    ResponseEntity<Map<String, String>> unavailable(PurchaseVerificationUnavailableException ignored) {
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(Map.of("code", "STORE_VERIFICATION_UNAVAILABLE"));
    }
}
