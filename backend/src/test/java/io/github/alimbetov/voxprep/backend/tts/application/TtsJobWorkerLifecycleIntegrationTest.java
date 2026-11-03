package io.github.alimbetov.voxprep.backend.tts.application;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsJobStatus;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsVoiceModelStatus;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsJobEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsJobRepository;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelRepository;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceRepository;
import io.github.alimbetov.voxprep.backend.tts.support.TtsTestAssets;
import jakarta.persistence.EntityManager;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@ActiveProfiles("test")
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Transactional
class TtsJobWorkerLifecycleIntegrationTest {

    @Autowired
    private TtsJobLeaseService leaseService;
    @Autowired
    private FileAssetRepository assetRepository;
    @Autowired
    private TtsVoiceRepository voiceRepository;
    @Autowired
    private TtsVoiceModelRepository modelRepository;
    @Autowired
    private TtsJobRepository jobRepository;
    @Autowired
    private JdbcTemplate jdbcTemplate;
    @Autowired
    private EntityManager entityManager;

    @Test
    void heartbeatMovesClaimToProcessingAndExtendsLease() {
        var job = pendingJob("heartbeat");
        var claim = leaseService.claimNext("worker-heartbeat", Duration.ofMinutes(1)).orElseThrow();
        var previousLeaseUntil = claim.leaseUntil();

        var heartbeat = leaseService.heartbeat(
                job.getId(), "worker-heartbeat", claim.leaseToken(), Duration.ofMinutes(5)).orElseThrow();

        assertThat(heartbeat.status()).isEqualTo(TtsJobStatus.PROCESSING);
        assertThat(heartbeat.leaseUntil()).isAfter(previousLeaseUntil);
        assertThat(heartbeat.leaseToken()).isEqualTo(claim.leaseToken());
    }

    @Test
    void staleTokenCannotHeartbeatCurrentLease() {
        var job = pendingJob("stale-heartbeat");
        leaseService.claimNext("worker-current", Duration.ofMinutes(5)).orElseThrow();

        assertThat(leaseService.heartbeat(
                job.getId(), "worker-current", UUID.randomUUID(), Duration.ofMinutes(5))).isEmpty();
    }

    @Test
    void currentLeaseCanFailJobAndClearsLeaseIdentity() {
        var job = pendingJob("fail");
        var claim = leaseService.claimNext("worker-fail", Duration.ofMinutes(5)).orElseThrow();

        assertThat(leaseService.fail(
                job.getId(),
                "worker-fail",
                claim.leaseToken(),
                "PIPER_EXIT_1",
                "Piper exited with code 1")).isTrue();

        jdbcTemplate.queryForMap("""
                select status, lease_owner, lease_token, lease_until, failure_code, failure_message, failed_at
                  from app.tts_job
                 where id = ?
                """, job.getId()).forEach((key, value) -> {
                    if (key.startsWith("lease_")) {
                        assertThat(value).isNull();
                    }
                });

        entityManager.clear();
        var reloaded = jobRepository.findById(job.getId()).orElseThrow();
        assertThat(reloaded.getStatus()).isEqualTo(TtsJobStatus.FAILED);
        assertThat(reloaded.getFailureCode()).isEqualTo("PIPER_EXIT_1");
        assertThat(reloaded.getFailureMessage()).isEqualTo("Piper exited with code 1");
        assertThat(reloaded.getFailedAt()).isNotNull();
    }

    @Test
    void expiredLeaseCannotFailAfterAnotherWorkerMayReclaim() {
        var job = pendingJob("expired-fail");
        var claim = leaseService.claimNext("worker-old", Duration.ofMinutes(5)).orElseThrow();
        jdbcTemplate.update("update app.tts_job set lease_until = CURRENT_TIMESTAMP - INTERVAL '1 second' where id = ?", job.getId());

        assertThat(leaseService.fail(
                job.getId(), "worker-old", claim.leaseToken(), "STALE", "stale worker")).isFalse();
    }

    private TtsJobEntity pendingJob(String suffix) {
        var voice = voiceRepository.saveAndFlush(new TtsVoiceEntity(
                "voice-worker-" + suffix, "US English Lessac", "en-US", "US", "FEMALE", "NEUTRAL", true));
        var assets = TtsTestAssets.createModelAssets(assetRepository, "worker-" + suffix, 'a', 'b');
        var model = modelRepository.saveAndFlush(new TtsVoiceModelEntity(
                "model-worker-" + suffix,
                voice,
                TtsEngine.PIPER,
                "1.3.0",
                "en_US-lessac-medium-v1",
                assets.modelAssetId(),
                assets.configAssetId(),
                String.valueOf('a').repeat(64),
                String.valueOf('b').repeat(64),
                TtsVoiceModelStatus.ACTIVE,
                "MIT",
                "https://example.invalid/license",
                true,
                Instant.parse("2026-11-02T18:00:00Z")));
        return jobRepository.saveAndFlush(new TtsJobEntity(
                model,
                "Worker lifecycle " + suffix,
                String.format("%064x", Math.abs(suffix.hashCode()) + 1L)));
    }
}
