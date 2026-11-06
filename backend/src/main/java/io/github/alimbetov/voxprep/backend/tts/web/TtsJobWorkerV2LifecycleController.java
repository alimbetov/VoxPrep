package io.github.alimbetov.voxprep.backend.tts.web;

import io.github.alimbetov.voxprep.backend.tts.application.TtsJobLeaseService;
import io.github.alimbetov.voxprep.backend.tts.application.TtsJobLeaseState;
import io.github.alimbetov.voxprep.backend.tts.application.TtsOutputFinalizationService;
import io.github.alimbetov.voxprep.backend.tts.application.WorkerApiKeyVerifier;
import io.github.alimbetov.voxprep.backend.tts.application.WorkerDeliveryProperties;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import java.io.IOException;
import java.util.UUID;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * V2 callbacks: derive worker engine exclusively from its Bearer credential.
 * A worker cannot use an arbitrary workerId to mutate another engine's job.
 *
 * Kokoro remains disabled until its pinned voice bundle is persisted on the
 * job and the complete lifecycle is qualified. V1 Piper endpoints unchanged.
 */
@RestController
@RequestMapping("/internal/v2/tts/jobs")
public class TtsJobWorkerV2LifecycleController {

    private final WorkerApiKeyVerifier identities;
    private final WorkerDeliveryProperties config;
    private final TtsJobLeaseService leases;
    private final TtsOutputFinalizationService output;
    private final JdbcTemplate jdbc;

    public TtsJobWorkerV2LifecycleController(
            WorkerApiKeyVerifier identities, WorkerDeliveryProperties config,
            TtsJobLeaseService leases, TtsOutputFinalizationService output,
            JdbcTemplate jdbc) {
        this.identities = identities;
        this.config = config;
        this.leases = leases;
        this.output = output;
        this.jdbc = jdbc;
    }

    @PostMapping("/{jobId}/heartbeat")
    public ResponseEntity<TtsJobLeaseState> heartbeat(
            @PathVariable UUID jobId,
            @RequestHeader(name = HttpHeaders.AUTHORIZATION, required = false) String authorization,
            @RequestBody LeaseRequest request) {
        var principal = identities.authenticatedEngine(authorization);
        if (principal.isEmpty()) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        TtsEngine engine = principal.orElseThrow();
        if (!isEnabled(engine)) return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).build();
        if (request == null || request.leaseToken() == null || !validWorker(request.workerId())) {
            return ResponseEntity.badRequest().build();
        }
        return leases.heartbeatForEngine(
                jobId, request.workerId(), request.leaseToken(), engine, config.getLeaseDuration())
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.status(HttpStatus.CONFLICT).build());
    }

    @PostMapping("/{jobId}/fail")
    public ResponseEntity<Void> fail(
            @PathVariable UUID jobId,
            @RequestHeader(name = HttpHeaders.AUTHORIZATION, required = false) String authorization,
            @RequestBody FailRequest request) {
        var principal = identities.authenticatedEngine(authorization);
        if (principal.isEmpty()) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        TtsEngine engine = principal.orElseThrow();
        if (!isEnabled(engine)) return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).build();
        if (request == null || request.fileId() == null || request.leaseToken() == null
                || !validWorker(request.workerId())) {
            return ResponseEntity.badRequest().build();
        }
        try {
            boolean done = leases.failWorkerForEngine(
                    jobId, request.fileId(), request.workerId(), request.leaseToken(), engine,
                    request.errorCode(), request.errorMessage());
            return done ? ResponseEntity.noContent().build()
                    : ResponseEntity.status(HttpStatus.CONFLICT).build();
        } catch (IllegalArgumentException | NullPointerException invalid) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping(value = "/{jobId}/output", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Void> output(
            @PathVariable UUID jobId,
            @RequestHeader(name = HttpHeaders.AUTHORIZATION, required = false) String authorization,
            @RequestParam String workerId, @RequestParam UUID fileId,
            @RequestParam UUID leaseToken, @RequestParam String fingerprint,
            @RequestParam UUID voiceModelId,
            @RequestParam(required = false) String manifestSha256,
            @RequestParam String audioProfile, @RequestParam String sha256,
            @RequestParam long sizeBytes, @RequestParam(required = false) Long durationMs,
            @RequestPart("file") MultipartFile file) {
        var principal = identities.authenticatedEngine(authorization);
        if (principal.isEmpty()) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        TtsEngine engine = principal.orElseThrow();
        if (!isEnabled(engine)) return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).build();
        if (!validWorker(workerId)) return ResponseEntity.badRequest().build();

        // Fail closed before writing any RustFS bytes. The job's voice-model
        // engine is immutable. No credential can authorize the wrong engine.
        Integer allowed = jdbc.queryForObject("""
                SELECT count(*) FROM app.tts_job j
                  JOIN app.tts_voice_model vm ON vm.id = j.voice_model_id
                  LEFT JOIN app.tts_kokoro_job_snapshot snapshot
                    ON snapshot.job_id = j.id
                 WHERE j.id = ? AND j.voice_model_id = ? AND vm.engine = ?
                   AND j.file_id = ? AND j.fingerprint = ?
                   AND (
                     vm.engine = 'PIPER'
                     OR (snapshot.voice_model_id = j.voice_model_id
                       AND snapshot.fingerprint = j.fingerprint
                       AND snapshot.manifest_sha256 = ?
                       AND snapshot.fingerprint_version = 'tts-fingerprint-v2')
                   )
                """, Integer.class, jobId, voiceModelId, engine.name(), fileId, fingerprint,
                manifestSha256);
        if (allowed == null || allowed != 1) {
            return ResponseEntity.status(HttpStatus.CONFLICT).build();
        }
        try {
            var upload = new TtsOutputFinalizationService.OutputUpload(
                    jobId, workerId, fileId, leaseToken, fingerprint, voiceModelId,
                    audioProfile, sha256, sizeBytes, durationMs,
                    file.getContentType(), file.getBytes());
            return switch (output.finalizeOutput(upload)) {
                case CREATED -> ResponseEntity.status(HttpStatus.CREATED).build();
                case ALREADY_FINALIZED -> ResponseEntity.ok().build();
                case LEASE_LOST, REPLAY_MISMATCH ->
                        ResponseEntity.status(HttpStatus.CONFLICT).build();
            };
        } catch (IllegalArgumentException | IOException exception) {
            return ResponseEntity.badRequest().build();
        }
    }

    private boolean isEnabled(TtsEngine engine) {
        return engine == TtsEngine.PIPER
                || (engine == TtsEngine.KOKORO && config.isKokoroEnabled());
    }

    private static boolean validWorker(String value) {
        return value != null && !value.isBlank() && value.equals(value.strip()) && value.length() <= 128;
    }

    public record LeaseRequest(String workerId, UUID leaseToken) { }
    public record FailRequest(
            UUID fileId, String workerId, UUID leaseToken,
            String errorCode, String errorMessage) { }
}
