package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import java.nio.charset.StandardCharsets;
import java.util.Optional;
import java.security.MessageDigest;
import org.springframework.stereotype.Component;

@Component
public class WorkerApiKeyVerifier {

    private static final String BEARER_PREFIX = "Bearer ";
    private final WorkerDeliveryProperties properties;

    public WorkerApiKeyVerifier(WorkerDeliveryProperties properties) {
        this.properties = properties;
    }

    /**
     * V2 engine permission is derived from the authenticated credential,
     * never from workerId or a client-advertised capabilities list.
     */
    public Optional<TtsEngine> authenticatedEngine(String authorization) {
        String supplied = bearerToken(authorization);
        if (supplied == null) {
            return Optional.empty();
        }
        String piper = properties.getApiKey();
        String kokoro = properties.getKokoroApiKey();
        // Reject any ambiguous shared credential. A misconfiguration must fail closed.
        if (!kokoro.isBlank() && safeEquals(piper, kokoro)) {
            return Optional.empty();
        }
        if (safeEquals(piper, supplied)) {
            return Optional.of(TtsEngine.PIPER);
        }
        if (!kokoro.isBlank() && safeEquals(kokoro, supplied)) {
            return Optional.of(TtsEngine.KOKORO);
        }
        return Optional.empty();
    }

    public boolean authorized(String authorization) {
        String supplied = bearerToken(authorization);
        return supplied != null && safeEquals(properties.getApiKey(), supplied);
    }
    private static String bearerToken(String authorization) {
        if (authorization == null || authorization.length() <= BEARER_PREFIX.length()
                || !authorization.regionMatches(true, 0, BEARER_PREFIX, 0, BEARER_PREFIX.length())) {
            return null;
        }
        return authorization.substring(BEARER_PREFIX.length());
    }

    private static boolean safeEquals(String expected, String supplied) {
        return MessageDigest.isEqual(
                expected.getBytes(StandardCharsets.UTF_8),
                supplied.getBytes(StandardCharsets.UTF_8));
    }
}
