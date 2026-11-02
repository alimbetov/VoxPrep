package io.github.alimbetov.voxprep.backend.tts.web;

import io.github.alimbetov.voxprep.backend.tts.application.TtsJobLeaseClaim;
import io.github.alimbetov.voxprep.backend.tts.application.TtsJobLeaseService;
import io.github.alimbetov.voxprep.backend.tts.application.TtsJobLeaseState;
import io.github.alimbetov.voxprep.backend.tts.application.WorkerApiKeyVerifier;
import io.github.alimbetov.voxprep.backend.tts.application.WorkerDeliveryProperties;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/internal/tts/jobs")
public class TtsJobWorkerController {

    private final TtsJobLeaseService leaseService;
    private final WorkerDeliveryProperties properties;
    private final WorkerApiKeyVerifier apiKeyVerifier;

    public TtsJobWorkerController(
            TtsJobLeaseService leaseService,
            WorkerDeliveryProperties properties,
            WorkerApiKeyVerifier apiKeyVerifier) {
        this.leaseService = leaseService;
        this.properties = properties;
        this.apiKeyVerifier = apiKeyVerifier;
    }

    @PostMapping("/claim")
    public ResponseEntity<TtsJobLeaseClaim> claim(
            @RequestHeader(name = TtsModelDeliveryController.WORKER_KEY_HEADER, required = false) String workerKey,
            @RequestBody ClaimRequest request) {
        if (!apiKeyVerifier.authorized(workerKey)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return leaseService.claimNext(request.workerId(), properties.getLeaseDuration())
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    @PostMapping("/{jobId}/heartbeat")
    public ResponseEntity<TtsJobLeaseState> heartbeat(
            @PathVariable UUID jobId,
            @RequestHeader(name = TtsModelDeliveryController.WORKER_KEY_HEADER, required = false) String workerKey,
            @RequestBody LeaseRequest request) {
        if (!apiKeyVerifier.authorized(workerKey)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return leaseService.heartbeat(jobId, request.workerId(), request.leaseToken(), properties.getLeaseDuration())
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.status(HttpStatus.CONFLICT).build());
    }

    @PostMapping("/{jobId}/fail")
    public ResponseEntity<Void> fail(
            @PathVariable UUID jobId,
            @RequestHeader(name = TtsModelDeliveryController.WORKER_KEY_HEADER, required = false) String workerKey,
            @RequestBody FailRequest request) {
        if (!apiKeyVerifier.authorized(workerKey)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        boolean failed = leaseService.fail(
                jobId,
                request.workerId(),
                request.leaseToken(),
                request.failureCode(),
                request.failureMessage());
        return failed
                ? ResponseEntity.noContent().build()
                : ResponseEntity.status(HttpStatus.CONFLICT).build();
    }

    public record ClaimRequest(String workerId) {
    }

    public record LeaseRequest(String workerId, UUID leaseToken) {
    }

    public record FailRequest(String workerId, UUID leaseToken, String failureCode, String failureMessage) {
    }
}
