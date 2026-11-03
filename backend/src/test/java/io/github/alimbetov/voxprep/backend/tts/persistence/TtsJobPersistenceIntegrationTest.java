package io.github.alimbetov.voxprep.backend.tts.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsJobStatus;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsVoiceModelStatus;
import io.github.alimbetov.voxprep.backend.tts.support.TtsTestAssets;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@ActiveProfiles("test")
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Transactional
class TtsJobPersistenceIntegrationTest {

    private static final String SOURCE_PROVIDER = "huggingface";
    private static final String SOURCE_REPOSITORY = "rhasspy/piper-voices";
    private static final String SOURCE_REVISION = "a517d785c98755ae1bb6c1bffd48a83e10c2f36f";

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

    @Test
    void persistsPendingJobAgainstExactVoiceModel() {
        var voice = voiceRepository.saveAndFlush(voice("voice-job"));
        var model = modelRepository.saveAndFlush(activeModel("model-job", voice, 'a', 'b'));
        var job = jobRepository.saveAndFlush(new TtsJobEntity(
                model,
                "Practice makes progress.",
                String.valueOf('c').repeat(64)));

        var loaded = jobRepository.findById(job.getId()).orElseThrow();
        assertThat(loaded.getStatus()).isEqualTo(TtsJobStatus.PENDING);
        assertThat(loaded.getVoiceModel().getId()).isEqualTo(model.getId());
        assertThat(loaded.getOutputAsset()).isNull();
        assertThat(jobRepository.findAllByStatusOrderByCreatedAtAsc(TtsJobStatus.PENDING))
                .extracting(TtsJobEntity::getId)
                .contains(job.getId());
    }

    @Test
    void persistsStorageIdentityAndRejectsDuplicates() {
        assetRepository.saveAndFlush(asset("tts/model-a.onnx", 'd'));
        assertThatThrownBy(() -> assetRepository.saveAndFlush(asset("tts/model-a.onnx", 'e')))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void databaseRejectsReadyJobWithoutOutputAsset() {
        var voice = voiceRepository.saveAndFlush(voice("voice-ready-guard"));
        var model = modelRepository.saveAndFlush(activeModel("model-ready-guard", voice, 'f', '0'));
        var job = jobRepository.saveAndFlush(new TtsJobEntity(
                model,
                "Guard READY output invariant.",
                String.valueOf('1').repeat(64)));

        assertThatThrownBy(() -> jdbcTemplate.update(
                        "update app.tts_job set status = 'READY' where id = ?",
                        job.getId()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void productionPersistenceTablesAreOwnedByNoLoginOwnerRole() {
        List<Map<String, Object>> rows = jdbcTemplate.queryForList("""
                select tablename, tableowner
                  from pg_tables
                 where schemaname = 'app'
                   and tablename in ('file_asset', 'tts_job')
                 order by tablename
                """);
        assertThat(rows).hasSize(2);
        assertThat(rows).allSatisfy(row -> assertThat(row.get("tableowner")).isEqualTo("voxprep_owner"));
    }

    private static TtsVoiceEntity voice(String code) {
        return new TtsVoiceEntity(code, "US English Lessac", "en-US", "US", "FEMALE", "NEUTRAL", true);
    }

    private TtsVoiceModelEntity activeModel(String code, TtsVoiceEntity voice, char modelHash, char configHash) {
        var assets = TtsTestAssets.createModelAssets(assetRepository, code, modelHash, configHash);
        return new TtsVoiceModelEntity(
                code,
                voice,
                TtsEngine.PIPER,
                "1.3.0",
                "en_US-lessac-medium-v1",
                assets.modelAssetId(),
                assets.configAssetId(),
                String.valueOf(modelHash).repeat(64),
                String.valueOf(configHash).repeat(64),
                SOURCE_PROVIDER,
                SOURCE_REPOSITORY,
                SOURCE_REVISION,
                TtsVoiceModelStatus.ACTIVE,
                "MIT",
                "https://example.invalid/license",
                true,
                Instant.parse("2026-11-02T18:00:00Z"));
    }

    private static FileAssetEntity asset(String objectKey, char hash) {
        return new FileAssetEntity(
                FileAssetKind.TTS_MODEL,
                FileAssetStatus.READY,
                "voxprep-test",
                objectKey,
                "application/octet-stream",
                1024,
                String.valueOf(hash).repeat(64));
    }
}
