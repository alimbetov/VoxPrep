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
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.Instant;
import java.util.HexFormat;
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
class TtsOutputReplayIntegrationTest {

    private static final String SOURCE_PROVIDER = "huggingface";
    private static final String SOURCE_REPOSITORY = "rhasspy/piper-voices";
    private static final String SOURCE_REVISION = "a517d785c98755ae1bb6c1bffd48a83e10c2f36f";

    @Autowired private TtsOutputFinalizationService outputService;
    @Autowired private TtsJobLeaseService leaseService;
    @Autowired private FileAssetRepository assetRepository;
    @Autowired private TtsVoiceRepository voiceRepository;
    @Autowired private TtsVoiceModelRepository modelRepository;
    @Autowired private TtsJobRepository jobRepository;
    @Autowired private JdbcTemplate jdbcTemplate;

    @Test
    void exactReplayAfterSuccessfulFinalizationIsIdempotent() {
        var fixture = pendingWorkerJob("replay");
        var claim = leaseService.claimNextForWorker("worker-replay", Duration.ofMinutes(5)).orElseThrow();
        byte[] mp3 = "replay-safe-mp3".getBytes(StandardCharsets.UTF_8);
        var upload = upload(fixture, claim.leaseToken(), "worker-replay", mp3, sha256(mp3));

        assertThat(outputService.finalizeOutput(upload))
                .isEqualTo(TtsOutputFinalizationService.FinalizationResult.CREATED);
        assertThat(outputService.finalizeOutput(upload))
                .isEqualTo(TtsOutputFinalizationService.FinalizationResult.ALREADY_FINALIZED);
        assertThat(jdbcTemplate.queryForObject(
                "select count(*) from app.file_asset where id = ?", Integer.class, fixture.fileId())).isEqualTo(1);
    }

    @Test
    void changedReplayIdentityFailsClosed() {
        var fixture = pendingWorkerJob("mismatch");
        var claim = leaseService.claimNextForWorker("worker-replay", Duration.ofMinutes(5)).orElseThrow();
        byte[] mp3 = "original-mp3".getBytes(StandardCharsets.UTF_8);
        assertThat(outputService.finalizeOutput(upload(
                fixture, claim.leaseToken(), "worker-replay", mp3, sha256(mp3))))
                .isEqualTo(TtsOutputFinalizationService.FinalizationResult.CREATED);

        byte[] different = "different-mp3".getBytes(StandardCharsets.UTF_8);
        assertThat(outputService.finalizeOutput(upload(
                fixture, claim.leaseToken(), "worker-replay", different, sha256(different))))
                .isEqualTo(TtsOutputFinalizationService.FinalizationResult.REPLAY_MISMATCH);
    }

    private TtsOutputFinalizationService.OutputUpload upload(
            Fixture fixture, UUID leaseToken, String workerId, byte[] bytes, String hash) {
        return new TtsOutputFinalizationService.OutputUpload(
                fixture.job().getId(), workerId, fixture.fileId(), leaseToken, fixture.fingerprint(),
                fixture.model().getId(), TtsOutputFinalizationService.AUDIO_PROFILE, hash,
                bytes.length, 1200L, TtsOutputFinalizationService.CONTENT_TYPE, bytes);
    }

    private Fixture pendingWorkerJob(String suffix) {
        UUID revisionId = UUID.randomUUID();
        jdbcTemplate.update("""
                INSERT INTO app.content_revision (
                    id, version, created_at, updated_at, content_code, content_type, revision_number,
                    lifecycle, checksum_sha256, title, subtitle, description, category_code, level_code,
                    minutes, availability)
                VALUES (?, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, ?, 'phrase', 1, 'DRAFT', ?,
                        'Title', 'Subtitle', 'Description', 'GENERAL', 'B1', 1, 'ACTIVE')
                """, revisionId, "tts-replay-" + suffix, String.valueOf('8').repeat(64));
        var voice = voiceRepository.saveAndFlush(new TtsVoiceEntity(
                "voice-replay-" + suffix, "US English", "en-US", "US", "FEMALE", "NEUTRAL", true));
        var assets = TtsTestAssets.createModelAssets(assetRepository, "replay-" + suffix, 'a', 'b');
        var model = modelRepository.saveAndFlush(new TtsVoiceModelEntity(
                "model-replay-" + suffix, voice, TtsEngine.PIPER, "1.3.0", "replay-v1",
                assets.modelAssetId(), assets.configAssetId(), String.valueOf('a').repeat(64),
                String.valueOf('b').repeat(64), SOURCE_PROVIDER, SOURCE_REPOSITORY, SOURCE_REVISION,
                TtsVoiceModelStatus.ACTIVE, "MIT", "https://example.invalid/license", true,
                Instant.parse("2026-11-02T18:00:00Z")));
        UUID fileId = UUID.randomUUID();
        String fingerprint = String.valueOf('c').repeat(64);
        var job = new TtsJobEntity(model, "Replay-safe output.", String.valueOf('d').repeat(64));
        job.prepareWorkerClaim(fileId, revisionId, "PRIMARY", "Replay-safe output.", "en-US", fingerprint);
        jobRepository.saveAndFlush(job);
        return new Fixture(job, model, fileId, fingerprint);
    }

    private static String sha256(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (Exception exception) {
            throw new IllegalStateException(exception);
        }
    }

    private record Fixture(TtsJobEntity job, TtsVoiceModelEntity model, UUID fileId, String fingerprint) { }
}
