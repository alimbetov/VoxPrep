package io.github.alimbetov.voxprep.backend.tts.web;

import io.github.alimbetov.voxprep.backend.tts.application.TtsModelDelivery;
import io.github.alimbetov.voxprep.backend.tts.application.TtsModelDeliveryService;
import io.github.alimbetov.voxprep.backend.tts.application.WorkerDeliveryProperties;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.NoSuchElementException;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/internal/tts/models")
public class TtsModelDeliveryController {

    public static final String WORKER_KEY_HEADER = "X-VoxPrep-Worker-Key";

    private final TtsModelDeliveryService deliveryService;
    private final WorkerDeliveryProperties properties;

    public TtsModelDeliveryController(
            TtsModelDeliveryService deliveryService,
            WorkerDeliveryProperties properties) {
        this.deliveryService = deliveryService;
        this.properties = properties;
    }

    @GetMapping("/{voiceModelId}")
    public ResponseEntity<TtsModelDelivery> getModel(
            @PathVariable UUID voiceModelId,
            @RequestHeader(name = WORKER_KEY_HEADER, required = false) String workerKey) {
        if (!authorized(workerKey)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        try {
            return ResponseEntity.ok(deliveryService.delivery(voiceModelId));
        } catch (NoSuchElementException exception) {
            return ResponseEntity.notFound().build();
        } catch (IllegalStateException exception) {
            return ResponseEntity.status(HttpStatus.CONFLICT).build();
        }
    }

    private boolean authorized(String supplied) {
        if (supplied == null) {
            return false;
        }
        return MessageDigest.isEqual(
                properties.getApiKey().getBytes(StandardCharsets.UTF_8),
                supplied.getBytes(StandardCharsets.UTF_8));
    }
}
