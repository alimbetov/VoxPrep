package io.github.alimbetov.voxprep.backend.tts.web;

import io.github.alimbetov.voxprep.backend.tts.application.TtsModelDeliveryService;
import io.github.alimbetov.voxprep.backend.tts.application.TtsModelDeliveryService.ArtifactType;
import io.github.alimbetov.voxprep.backend.tts.application.WorkerApiKeyVerifier;
import java.util.NoSuchElementException;
import java.util.UUID;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/internal/v1/tts/models")
public class TtsModelDeliveryController {

    private final TtsModelDeliveryService deliveryService;
    private final WorkerApiKeyVerifier tokenVerifier;

    public TtsModelDeliveryController(TtsModelDeliveryService deliveryService, WorkerApiKeyVerifier tokenVerifier) {
        this.deliveryService = deliveryService;
        this.tokenVerifier = tokenVerifier;
    }

    @GetMapping("/{voiceModelId}/model")
    public ResponseEntity<byte[]> model(
            @PathVariable UUID voiceModelId,
            @RequestHeader(name = HttpHeaders.AUTHORIZATION, required = false) String authorization) {
        return download(voiceModelId, ArtifactType.MODEL, authorization);
    }

    @GetMapping("/{voiceModelId}/config")
    public ResponseEntity<byte[]> config(
            @PathVariable UUID voiceModelId,
            @RequestHeader(name = HttpHeaders.AUTHORIZATION, required = false) String authorization) {
        return download(voiceModelId, ArtifactType.CONFIG, authorization);
    }

    private ResponseEntity<byte[]> download(UUID id, ArtifactType type, String authorization) {
        if (!tokenVerifier.authorized(authorization)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        try {
            var artifact = deliveryService.download(id, type);
            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(artifact.mediaType()))
                    .header("X-Content-SHA256", artifact.sha256())
                    .body(artifact.bytes());
        } catch (NoSuchElementException exception) {
            return ResponseEntity.notFound().build();
        }
    }
}
