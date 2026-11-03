package io.github.alimbetov.voxprep.backend.tts.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
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
class TtsVoiceCatalogueIntegrationTest {

    private static final String PROVIDER = "huggingface";
    private static final String REPOSITORY = "rhasspy/piper-voices";
    private static final String REVISION = "a517d785c98755ae1bb6c1bffd48a83e10c2f36f";

    @Autowired
    private FileAssetRepository assetRepository;

    @Autowired
    private TtsVoiceRepository voiceRepository;

    @Autowired
    private TtsVoiceModelRepository modelRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void persistsActivePiperModelAndSelectsExactDefaultModel() {
        var voice = voiceRepository.saveAndFlush(voice("voice-primary"));
        var model = modelRepository.saveAndFlush(activeModel("model-primary", voice, 'a', 'b'));
        voice.selectDefaultModel(model);
        voiceRepository.saveAndFlush(voice);

        var loaded = voiceRepository.findByCode("voice-primary").orElseThrow();
        assertThat(loaded.getDefaultModel().getId()).isEqualTo(model.getId());
        assertThat(model.selectableForNewJobs()).isTrue();
        assertThat(model.getSourceProvider()).isEqualTo(PROVIDER);
        assertThat(model.getSourceRepository()).isEqualTo(REPOSITORY);
        assertThat(model.getSourceRevision()).isEqualTo(REVISION);
        assertThat(modelRepository.findAllByVoice_IdAndStatusOrderByCodeAsc(
                        voice.getId(), TtsVoiceModelStatus.ACTIVE))
                .extracting(TtsVoiceModelEntity::getCode)
                .containsExactly("model-primary");
    }

    @Test
    void javaRejectsActiveModelWithoutPinnedProvenance() {
        var voice = voiceRepository.saveAndFlush(voice("voice-unpinned"));
        var assets = TtsTestAssets.createModelAssets(assetRepository, "unpinned", '7', '8');

        assertThatThrownBy(() -> new TtsVoiceModelEntity(
                        "model-unpinned",
                        voice,
                        TtsEngine.PIPER,
                        "1.3.0",
                        "en_US-lessac-medium-v1",
                        assets.modelAssetId(),
                        assets.configAssetId(),
                        String.valueOf('7').repeat(64),
                        String.valueOf('8').repeat(64),
                        TtsVoiceModelStatus.ACTIVE,
                        "MIT",
                        "https://example.invalid/license",
                        true,
                        Instant.parse("2026-11-02T18:00:00Z")))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("pinned source provenance");
    }

    @Test
    void databaseRejectsDirectActivationWithoutPinnedProvenance() {
        var voice = voiceRepository.saveAndFlush(voice("voice-db-policy"));
        var assets = TtsTestAssets.createModelAssets(assetRepository, "db-policy", '3', '4');
        var model = modelRepository.saveAndFlush(new TtsVoiceModelEntity(
                "model-db-policy",
                voice,
                TtsEngine.PIPER,
                "1.3.0",
                "en_US-lessac-medium-v1",
                assets.modelAssetId(),
                assets.configAssetId(),
                String.valueOf('3').repeat(64),
                String.valueOf('4').repeat(64),
                TtsVoiceModelStatus.READY_FOR_REVIEW,
                "MIT",
                "https://example.invalid/license",
                false,
                null));

        assertThatThrownBy(() -> jdbcTemplate.update(
                        "update app.tts_voice_model set status = 'ACTIVE', commercial_use_reviewed = true, approved_at = now() where id = ?",
                        model.getId()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void databaseRejectsDefaultModelFromAnotherVoice() {
        var firstVoice = voiceRepository.saveAndFlush(voice("voice-first"));
        var secondVoice = voiceRepository.saveAndFlush(voice("voice-second"));
        var foreignModel = modelRepository.saveAndFlush(activeModel("model-foreign", secondVoice, 'c', 'd'));

        assertThatThrownBy(() -> jdbcTemplate.update(
                        "update app.tts_voice set default_model_id = ? where id = ?",
                        foreignModel.getId(),
                        firstVoice.getId()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void databaseRejectsMutationOfExactModelExecutionIdentity() {
        var voice = voiceRepository.saveAndFlush(voice("voice-immutable"));
        var model = modelRepository.saveAndFlush(activeModel("model-immutable", voice, 'e', 'f'));

        assertThatThrownBy(() -> jdbcTemplate.update(
                        "update app.tts_voice_model set model_sha256 = ? where id = ?",
                        String.valueOf('0').repeat(64),
                        model.getId()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void nonActiveModelIsNotSelectableForNewJobs() {
        var voice = voiceRepository.saveAndFlush(voice("voice-review"));
        var assets = TtsTestAssets.createModelAssets(assetRepository, "review", '1', '2');
        var model = new TtsVoiceModelEntity(
                "model-review",
                voice,
                TtsEngine.PIPER,
                "1.3.0",
                "en_US-lessac-medium-v1",
                assets.modelAssetId(),
                assets.configAssetId(),
                String.valueOf('1').repeat(64),
                String.valueOf('2').repeat(64),
                TtsVoiceModelStatus.READY_FOR_REVIEW,
                "MIT",
                "https://example.invalid/license",
                true,
                null);

        modelRepository.saveAndFlush(model);
        assertThat(model.selectableForNewJobs()).isFalse();
    }

    @Test
    void productionTtsCatalogueTablesAreOwnedByNoLoginOwnerRole() {
        List<Map<String, Object>> rows = jdbcTemplate.queryForList("""
                select tablename, tableowner
                  from pg_tables
                 where schemaname = 'app'
                   and tablename in ('tts_voice', 'tts_voice_model')
                 order by tablename
                """);
        assertThat(rows).hasSize(2);
        assertThat(rows).allSatisfy(row -> assertThat(row.get("tableowner")).isEqualTo("voxprep_owner"));
    }

    private static TtsVoiceEntity voice(String code) {
        return new TtsVoiceEntity(
                code,
                "US English Lessac",
                "en-US",
                "US",
                "FEMALE",
                "NEUTRAL",
                true);
    }

    private TtsVoiceModelEntity activeModel(
            String code,
            TtsVoiceEntity voice,
            char modelHash,
            char configHash) {
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
                PROVIDER,
                REPOSITORY,
                REVISION,
                TtsVoiceModelStatus.ACTIVE,
                "MIT",
                "https://example.invalid/license",
                true,
                Instant.parse("2026-11-02T18:00:00Z"));
    }
}
