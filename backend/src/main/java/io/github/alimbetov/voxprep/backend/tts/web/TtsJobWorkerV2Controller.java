package io.github.alimbetov.voxprep.backend.tts.web;

import io.github.alimbetov.voxprep.backend.tts.application.TtsJobLeaseService;
import io.github.alimbetov.voxprep.backend.tts.application.WorkerApiKeyVerifier;
import io.github.alimbetov.voxprep.backend.tts.application.WorkerDeliveryProperties;
import io.github.alimbetov.voxprep.backend.tts.application.WorkerTtsJobClaim;
import io.github.alimbetov.voxprep.backend.tts.application.KokoroWorkerTtsJobClaim;
import java.math.BigDecimal;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import java.util.UUID;
import java.time.Instant;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Versioned engine-scoped claim. Full Kokoro artifact/voice delivery is a
 * subsequent K1 slice; Kokoro claims fail closed until that contract exists.
 * The legacy /internal/v1/tts/jobs endpoints are unchanged.
 */
@RestController
@RequestMapping("/internal/v2/tts/jobs")
public class TtsJobWorkerV2Controller {

    private final TtsJobLeaseService leases;
    private final WorkerApiKeyVerifier credentials;
    private final WorkerDeliveryProperties properties;

    public TtsJobWorkerV2Controller(
            TtsJobLeaseService leases,
            WorkerApiKeyVerifier credentials,
            WorkerDeliveryProperties properties) {
        this.leases = leases;
        this.credentials = credentials;
        this.properties = properties;
    }

    @PostMapping("/claim")
    public ResponseEntity<ClaimV2> claim(
            @RequestHeader(name = HttpHeaders.AUTHORIZATION, required = false) String authorization,
            @RequestBody ClaimRequestV2 request) {
        var principal = credentials.authenticatedEngine(authorization);
        if (principal.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        TtsEngine engine = principal.orElseThrow();
        if (request == null || request.workerId() == null
                || request.workerId().isBlank()
                || !request.workerId().equals(request.workerId().strip())
                || request.workerId().length() > 128) {
            return ResponseEntity.badRequest().build();
        }
        if (request.supportedEngine() != null && request.supportedEngine() != engine) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        // KOKORO must remain disabled until artifact manifests, immutable V2
        // fingerprints, callbacks, and deployment credentials are qualified.
        if (engine == TtsEngine.KOKORO) {
            if (!properties.isKokoroEnabled()) {
                return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).build();
            }
            return leases.claimNextKokoroForWorker(request.workerId(), properties.getLeaseDuration())
                    .map(claim -> ResponseEntity.ok(ClaimV2.fromKokoro(claim)))
                    .orElseGet(() -> ResponseEntity.noContent().build());
        }
        return leases.claimNextForEngine(request.workerId(), engine, properties.getLeaseDuration())
                .map(claim -> ResponseEntity.ok(ClaimV2.from(engine, claim)))
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    public record ClaimRequestV2(String workerId, TtsEngine supportedEngine) { }

    public record ClaimV2(
            TtsEngine engine,
            UUID jobId, UUID fileId, UUID contentRevisionId,
            String audioRole, String normalizedTtsText, String language,
            UUID voiceModelId, String voiceModelCode,
            String modelSha256, String configSha256, String fingerprint,
            UUID leaseToken, Instant leaseUntil,
            UUID bundleId, String bundleModelCode, String manifestSha256,
            String voiceCode, String voiceArtifactSha256,
            String phonemizerVersion, String engineVersion, BigDecimal speed) {
        static ClaimV2 from(TtsEngine engine, WorkerTtsJobClaim c) {
            return new ClaimV2(engine, c.jobId(), c.fileId(), c.contentRevisionId(),
                    c.audioRole(), c.normalizedTtsText(), c.language(),
                    c.voiceModelId(), c.voiceModelCode(), c.modelSha256(),
                    c.configSha256(), c.fingerprint(), c.leaseToken(), c.leaseUntil(),
                    null, null, null, null, null, null, null, null);
        }

        static ClaimV2 fromKokoro(KokoroWorkerTtsJobClaim claim) {
            WorkerTtsJobClaim c = claim.job();
            return new ClaimV2(
                    TtsEngine.KOKORO, c.jobId(), c.fileId(), c.contentRevisionId(),
                    c.audioRole(), c.normalizedTtsText(), c.language(),
                    c.voiceModelId(), c.voiceModelCode(), null, null,
                    c.fingerprint(), c.leaseToken(), c.leaseUntil(),
                    claim.bundleId(), claim.bundleModelCode(), claim.manifestSha256(),
                    claim.voiceCode(), claim.voiceArtifactSha256(),
                    claim.phonemizerVersion(), claim.engineVersion(), claim.speed());
        }
    }
}
