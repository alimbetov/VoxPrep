package io.github.alimbetov.voxprep.backend.tts.web;

import io.github.alimbetov.voxprep.backend.tts.application.TtsJobLeaseService;
import io.github.alimbetov.voxprep.backend.tts.application.TtsJobLeaseState;
import io.github.alimbetov.voxprep.backend.tts.application.TtsOutputFinalizationService;
import io.github.alimbetov.voxprep.backend.tts.application.WorkerApiKeyVerifier;
import io.github.alimbetov.voxprep.backend.tts.application.WorkerDeliveryProperties;
import io.github.alimbetov.voxprep.backend.tts.application.WorkerTtsJobClaim;
import java.io.IOException;
import java.util.UUID;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/internal/v1/tts/jobs")
public class TtsJobWorkerController {

    private final TtsJobLeaseService leaseService;
    private final TtsOutputFinalizationService outputService;
    private final WorkerDeliveryProperties properties;
    private final WorkerApiKeyVerifier tokenVerifier;

    public TtsJobWorkerController(
            TtsJobLeaseService leaseService,
            TtsOutputFinalizationService outputService,
            WorkerDeliveryProperties properties,
            WorkerApiKeyVerifier tokenVerifier) {
        this.leaseService = leaseService;
        this.outputService = outputService;
        this.properties = properties;
        this.tokenVerifier = tokenVerifier;
    }

    @PostMapping("/claim")
    public ResponseEntity<WorkerTtsJobClaim> claim(
            @RequestHeader(name = HttpHeaders.AUTHORIZATION, required = false) String authorization,
            @RequestBody ClaimRequest request) {
        if (!tokenVerifier.authorized(authorization)) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        return leaseService.claimNextForWorker(request.workerId(), properties.getLeaseDuration())
                .map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.noContent().build());
    }

    @PostMapping("/{jobId}/heartbeat")
    public ResponseEntity<TtsJobLeaseState> heartbeat(
            @PathVariable UUID jobId,
            @RequestHeader(name = HttpHeaders.AUTHORIZATION, required = false) String authorization,
            @RequestBody LeaseRequest request) {
        if (!tokenVerifier.authorized(authorization)) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        return leaseService.heartbeat(jobId, request.workerId(), request.leaseToken(), properties.getLeaseDuration())
                .map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.status(HttpStatus.CONFLICT).build());
    }

    @PostMapping("/{jobId}/fail")
    public ResponseEntity<Void> fail(
            @PathVariable UUID jobId,
            @RequestHeader(name = HttpHeaders.AUTHORIZATION, required = false) String authorization,
            @RequestBody FailRequest request) {
        if (!tokenVerifier.authorized(authorization)) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        boolean failed = leaseService.failWorker(jobId, request.fileId(), request.workerId(), request.leaseToken(),
                request.errorCode(), request.errorMessage());
        return failed ? ResponseEntity.noContent().build() : ResponseEntity.status(HttpStatus.CONFLICT).build();
    }

    @PostMapping(value = "/{jobId}/output", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Void> output(
            @PathVariable UUID jobId,
            @RequestHeader(name = HttpHeaders.AUTHORIZATION, required = false) String authorization,
            @RequestParam String workerId,
            @RequestParam UUID fileId,
            @RequestParam UUID leaseToken,
            @RequestParam String fingerprint,
            @RequestParam UUID voiceModelId,
            @RequestParam String audioProfile,
            @RequestParam String sha256,
            @RequestParam long sizeBytes,
            @RequestParam(required = false) Long durationMs,
            @RequestPart("file") MultipartFile file) {
        if (!tokenVerifier.authorized(authorization)) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        try {
            var result = outputService.finalizeOutput(new TtsOutputFinalizationService.OutputUpload(
                    jobId, workerId, fileId, leaseToken, fingerprint, voiceModelId, audioProfile,
                    sha256, sizeBytes, durationMs, file.getContentType(), file.getBytes()));
            return result == TtsOutputFinalizationService.FinalizationResult.CREATED
                    ? ResponseEntity.status(HttpStatus.CREATED).build()
                    : ResponseEntity.status(HttpStatus.CONFLICT).build();
        } catch (IllegalArgumentException | IOException exception) {
            return ResponseEntity.badRequest().build();
        }
    }

    public record ClaimRequest(String workerId) { }
    public record LeaseRequest(String workerId, UUID leaseToken) { }
    public record FailRequest(UUID fileId, String workerId, UUID leaseToken, String errorCode, String errorMessage) { }
}
