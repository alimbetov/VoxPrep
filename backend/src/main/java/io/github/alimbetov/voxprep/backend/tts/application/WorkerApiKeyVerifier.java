package io.github.alimbetov.voxprep.backend.tts.application;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import org.springframework.stereotype.Component;

@Component
public class WorkerApiKeyVerifier {

    private final WorkerDeliveryProperties properties;

    public WorkerApiKeyVerifier(WorkerDeliveryProperties properties) {
        this.properties = properties;
    }

    public boolean authorized(String supplied) {
        if (supplied == null) {
            return false;
        }
        return MessageDigest.isEqual(
                properties.getApiKey().getBytes(StandardCharsets.UTF_8),
                supplied.getBytes(StandardCharsets.UTF_8));
    }
}
