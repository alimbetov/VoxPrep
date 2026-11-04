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
class TtsOutputFinalizationIntegrationTest {

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
    @Autowired private EntityManager entityManager;

    @Test
    void currentLeaseFinalizesRustFsAssetReadyJobAndContentBinding() {
        var fixture = pendingWorkerJob("finalize");
        var claim = leaseService.claimNextForWorker("worker-output", Duration.ofMinutes(5)).orElseThrow();
        byte[] mp3 = "qualified-mp3-payload".getBytes(StandardCharsets.UTF_8);
        String hash = sha256(mp3);

        var result = outputService.finalizeOutput(new TtsOutputFinalizationService.OutputUpload(
                fixture.job().getId(), "worker-output", fixture.fileId(), claim.leaseToken(), fixture.fingerprint(),
                fixture.model().getId(), TtsOutputFinalizationService.AUDIO_PROFILE, hash, mp3.length, 1234L,
                TtsOutputFinalizationService.CONTENT_TYPE, mp3));

        assertThat(result).isEqualTo(TtsOutputFinalizationService.FinalizationResult.CREATED);
        entityManager.clear();
        var job = jobRepository.findById(fixture.job().getId()).orElseThrow();
        assertThat(job.getStatus()).isEqualTo(TtsJobStatus.READY);
        assertThat(job.getOutputAsset()).isNotNull();
        assertThat(job.getOutputAsset().getId()).isEqualTo(fixture.fileId());
        assertThat(jdbcTemplate.queryForObject(
                "select audio_profile from app.file_asset where id = ?", String.class, fixture.fileId()))
                .isEqualTo(TtsOutputFinalizationService.AUDIO_PROFILE);
        assertThat(jdbcTemplate.queryForObject("""
                select count(*) from app.content_asset_binding
                 where content_revision_id = ?
                   and role = 'PRONUNCIATION'
                   and file_asset_id = ?
                   and source_fingerprint = ?
                """, Integer.class, fixture.revisionId(), fixture.fileId(), fixture.fingerprint()))
                .isEqualTo(1);
    }

    @Test
    void staleLeaseCannotFinalizeOutput() {
        var fixture = pendingWorkerJob("stale-output");
        var claim = leaseService.claimNextForWorker("worker-old", Duration.ofMinutes(5)).orElseThrow();
        jdbcTemplate.update("update app.tts_job set lease_until = CURRENT_TIMESTAMP - INTERVAL '1 second' where id = ?",
                fixture.job().getId());
        byte[] mp3 = "stale".getBytes(StandardCharsets.UTF_8);

        var result = outputService.finalizeOutput(new TtsOutputFinalizationService.OutputUpload(
                fixture.job().getId(), "worker-old", fixture.fileId(), claim.leaseToken(), fixture.fingerprint(),
                fixture.model().getId(), TtsOutputFinalizationService.AUDIO_PROFILE, sha256(mp3), mp3.length, 100L,
                TtsOutputFinalizationService.CONTENT_TYPE, mp3));

        assertThat(result).isEqualTo(TtsOutputFinalizationService.FinalizationResult.LEASE_LOST);
        assertThat(jdbcTemplate.queryForObject(
                "select count(*) from app.file_asset where id = ?", Integer.class, fixture.fileId())).isZero();
        assertThat(jdbcTemplate.queryForObject(
                "select count(*) from app.content_asset_binding where content_revision_id = ?",
                Integer.class, fixture.revisionId())).isZero();
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
                """, revisionId, "tts-output-" + suffix, String.valueOf('9').repeat(64));

        var voice = voiceRepository.saveAndFlush(new TtsVoiceEntity(
                "voice-output-" + suffix, "US English", "en-US", "US", "FEMALE", "NEUTRAL", true));
        var assets = TtsTestAssets.createModelAssets(assetRepository, "output-" + suffix, 'a', 'b');
        var model = modelRepository.saveAndFlush(new TtsVoiceModelEntity(
                "model-output-" + suffix, voice, TtsEngine.PIPER, "1.3.0", "output-v1",
                assets.modelAssetId(), assets.configAssetId(), String.valueOf('a').repeat(64),
                String.valueOf('b').repeat(64), SOURCE_PROVIDER, SOURCE_REPOSITORY, SOURCE_REVISION,
                TtsVoiceModelStatus.ACTIVE, "MIT", "https://example.invalid/license", true,
                Instant.parse("2026-11-02T18:00:00Z")));
        UUID fileId = UUID.randomUUID();
        String fingerprint = String.valueOf('c').repeat(64);
        var job = new TtsJobEntity(model, "Tell me about yourself.", String.valueOf('d').repeat(64));
        job.prepareWorkerClaim(
                fileId, revisionId, "pronunciation", "Tell me about yourself.", "en-US", fingerprint);
        jobRepository.saveAndFlush(job);
        return new Fixture(job, model, revisionId, fileId, fingerprint);
    }

    private static String sha256(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (Exception exception) {
            throw new IllegalStateException(exception);
        }
    }

    private record Fixture(
            TtsJobEntity job,
            TtsVoiceModelEntity model,
            UUID revisionId,
            UUID fileId,
            String fingerprint) { }
}
