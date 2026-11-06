package io.github.alimbetov.voxprep.backend.tts.application;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsVoiceModelStatus;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsJobEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsJobRepository;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelRepository;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceRepository;
import io.github.alimbetov.voxprep.backend.tts.support.TtsTestAssets;
import java.time.Duration;
import java.time.Instant;
import java.util.HashSet;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.support.TransactionTemplate;

@ActiveProfiles("test")
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class TtsJobLeaseIntegrationTest {

    private static final String SOURCE_PROVIDER = "huggingface";
    private static final String SOURCE_REPOSITORY = "rhasspy/piper-voices";
    private static final String SOURCE_REVISION = "a517d785c98755ae1bb6c1bffd48a83e10c2f36f";

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
    private TransactionTemplate transactionTemplate;

    @BeforeEach
    @AfterEach
    void cleanCommittedLeaseFixtures() {
        transactionTemplate.executeWithoutResult(status -> {
            jdbcTemplate.update("delete from app.tts_job");
            jdbcTemplate.update("delete from app.tts_voice_model");
            jdbcTemplate.update("delete from app.tts_voice");
            // Only remove this suite's assets. Other integration tests leave READY
            // media bindings referencing their own FileAsset rows.
            jdbcTemplate.update("""
                    delete from app.file_asset
                     where bucket = 'voxprep-assets'
                       and object_key like 'tts/models/lease-%'
                    """);
        });
    }

    @Test
    void concurrentWorkersClaimDifferentJobs() throws Exception {
        List<UUID> jobIds = createPendingJobs("concurrent", 2);
        try (var executor = Executors.newFixedThreadPool(2)) {
            var ready = new CountDownLatch(2);
            var start = new CountDownLatch(1);
            var first = executor.submit(() -> claimAfterSignal("worker-a", ready, start));
            var second = executor.submit(() -> claimAfterSignal("worker-b", ready, start));
            assertThat(ready.await(5, TimeUnit.SECONDS)).isTrue();
            start.countDown();
            var firstClaim = first.get(5, TimeUnit.SECONDS);
            var secondClaim = second.get(5, TimeUnit.SECONDS);
            assertThat(firstClaim.jobId()).isNotEqualTo(secondClaim.jobId());
            assertThat(new HashSet<>(List.of(firstClaim.jobId(), secondClaim.jobId())))
                    .containsExactlyInAnyOrderElementsOf(jobIds);
            assertThat(firstClaim.attemptCount()).isEqualTo(1);
            assertThat(secondClaim.attemptCount()).isEqualTo(1);
        }
    }

    @Test
    void legacyGenericClaimNeverStealsKokoroJob() {
        UUID kokoroJob = createPendingJobs("kokoro-only", 1, TtsEngine.KOKORO).getFirst();
        assertThat(leaseService.claimNext("legacy-piper", Duration.ofMinutes(5))).isEmpty();
        assertThat(jdbcTemplate.queryForObject(
                "select status from app.tts_job where id = ?", String.class, kokoroJob))
                .isEqualTo("PENDING");
    }

    @Test
    void legacyGenericClaimSkipsEarlierKokoroAndClaimsPiper() {
        UUID kokoroJob = createPendingJobs("kokoro-first", 1, TtsEngine.KOKORO).getFirst();
        UUID piperJob = createPendingJobs("piper-second", 1, TtsEngine.PIPER).getFirst();
        var claimed = leaseService.claimNext("legacy-piper", Duration.ofMinutes(5)).orElseThrow();
        assertThat(claimed.jobId()).isEqualTo(piperJob);
        assertThat(jdbcTemplate.queryForObject(
                "select status from app.tts_job where id = ?", String.class, kokoroJob))
                .isEqualTo("PENDING");
    }

    @Test
    void activeLeaseIsNotClaimable() {
        UUID jobId = createPendingJobs("active", 1).getFirst();
        jdbcTemplate.update("""
                update app.tts_job
                   set status = 'CLAIMED', lease_owner = 'worker-active', lease_token = ?,
                       lease_until = CURRENT_TIMESTAMP + INTERVAL '5 minutes',
                       claimed_at = CURRENT_TIMESTAMP, attempt_count = 1
                 where id = ?
                """, UUID.randomUUID(), jobId);
        assertThat(leaseService.claimNext("worker-other", Duration.ofMinutes(5))).isEmpty();
    }

    @Test
    void expiredLeaseIsReclaimedWithNewTokenAndAttempt() {
        UUID jobId = createPendingJobs("expired", 1).getFirst();
        UUID oldToken = UUID.randomUUID();
        jdbcTemplate.update("""
                update app.tts_job
                   set status = 'CLAIMED', lease_owner = 'worker-old', lease_token = ?,
                       lease_until = CURRENT_TIMESTAMP - INTERVAL '1 minute',
                       claimed_at = CURRENT_TIMESTAMP - INTERVAL '2 minutes', attempt_count = 1
                 where id = ?
                """, oldToken, jobId);
        var claim = leaseService.claimNext("worker-new", Duration.ofMinutes(5)).orElseThrow();
        assertThat(claim.jobId()).isEqualTo(jobId);
        assertThat(claim.leaseOwner()).isEqualTo("worker-new");
        assertThat(claim.leaseToken()).isNotEqualTo(oldToken);
        assertThat(claim.attemptCount()).isEqualTo(2);
    }

    private TtsJobLeaseClaim claimAfterSignal(String workerId, CountDownLatch ready, CountDownLatch start)
            throws InterruptedException {
        ready.countDown();
        if (!start.await(5, TimeUnit.SECONDS)) {
            throw new IllegalStateException("claim start signal timed out");
        }
        return leaseService.claimNext(workerId, Duration.ofMinutes(5)).orElseThrow();
    }

    private List<UUID> createPendingJobs(String suffix, int count) {
        return createPendingJobs(suffix, count, TtsEngine.PIPER);
    }

    private List<UUID> createPendingJobs(String suffix, int count, TtsEngine engine) {
        return transactionTemplate.execute(status -> {
            var voice = voiceRepository.saveAndFlush(new TtsVoiceEntity(
                    "voice-lease-" + suffix, "US English Lessac", "en-US", "US", "FEMALE", "NEUTRAL", true));
            var assets = TtsTestAssets.createModelAssets(assetRepository, "lease-" + suffix, 'a', 'b');
            var model = modelRepository.saveAndFlush(new TtsVoiceModelEntity(
                    "model-lease-" + suffix,
                    voice,
                    engine,
                    "1.3.0",
                    "en_US-lessac-medium-v1",
                    assets.modelAssetId(),
                    assets.configAssetId(),
                    String.valueOf('a').repeat(64),
                    String.valueOf('b').repeat(64),
                    SOURCE_PROVIDER,
                    SOURCE_REPOSITORY,
                    SOURCE_REVISION,
                    TtsVoiceModelStatus.ACTIVE,
                    "MIT",
                    "https://example.invalid/license",
                    true,
                    Instant.parse("2026-11-02T18:00:00Z")));
            return java.util.stream.IntStream.range(0, count)
                    .mapToObj(index -> jobRepository.saveAndFlush(new TtsJobEntity(
                            model,
                            "Lease qualification " + suffix + " " + index,
                            String.format("%064x", index + 1))).getId())
                    .toList();
        });
    }
}
