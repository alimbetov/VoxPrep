package io.github.alimbetov.voxprep.backend.tts.application;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import org.springframework.stereotype.Component;

@Component
public class WorkerApiKeyVerifier {

    private static final String BEARER_PREFIX = "Bearer ";
    private final WorkerDeliveryProperties properties;

    public WorkerApiKeyVerifier(WorkerDeliveryProperties properties) {
        this.properties = properties;
    }

    public boolean authorized(String authorization) {
        if (authorization == null || authorization.length() <= BEARER_PREFIX.length()
                || !authorization.regionMatches(true, 0, BEARER_PREFIX, 0, BEARER_PREFIX.length())) {
            return false;
        }
        String supplied = authorization.substring(BEARER_PREFIX.length());
        return MessageDigest.isEqual(
                properties.getApiKey().getBytes(StandardCharsets.UTF_8),
                supplied.getBytes(StandardCharsets.UTF_8));
    }
}
