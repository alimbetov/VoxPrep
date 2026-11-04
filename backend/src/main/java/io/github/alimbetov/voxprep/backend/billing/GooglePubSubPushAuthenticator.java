package io.github.alimbetov.voxprep.backend.billing;

import com.google.auth.oauth2.TokenVerifier;
import java.util.Objects;

/**
 * Validates Google-signed Pub/Sub push JWTs, not the untrusted push envelope.
 * The expected audience and service-account identity are configuration values
 * of the specific authenticated push subscription.
 */
public final class GooglePubSubPushAuthenticator {
    private final TokenVerifier verifier;
    private final String serviceAccountEmail;

    public GooglePubSubPushAuthenticator(String audience, String serviceAccountEmail) {
        if (audience == null || audience.isBlank()
                || serviceAccountEmail == null || serviceAccountEmail.isBlank()
                || !serviceAccountEmail.endsWith(".gserviceaccount.com")) {
            throw new IllegalStateException("Google Pub/Sub authenticated push identity is not configured");
        }
        this.serviceAccountEmail = serviceAccountEmail;
        this.verifier = TokenVerifier.newBuilder()
                .setAudience(audience)
                .setIssuer("https://accounts.google.com")
                .build();
    }

    public boolean authenticated(String authorizationHeader) {
        if (authorizationHeader == null || !authorizationHeader.startsWith("Bearer ")
                || authorizationHeader.length() > 16391) {
            return false;
        }
        try {
            var signature = verifier.verify(authorizationHeader.substring(7));
            var claims = signature.getPayload();
            return Objects.equals(serviceAccountEmail, claims.get("email"))
                    && Boolean.TRUE.equals(claims.get("email_verified"));
        } catch (Exception invalidSignatureOrNetwork) {
            // An unavailable Google signing-key endpoint must fail closed.
            return false;
        }
    }
}
