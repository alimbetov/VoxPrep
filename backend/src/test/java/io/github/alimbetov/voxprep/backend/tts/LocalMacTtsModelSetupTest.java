package io.github.alimbetov.voxprep.backend.tts;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.alimbetov.voxprep.backend.tts.application.*;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsVoiceModelStatus;
import io.github.alimbetov.voxprep.backend.tts.persistence.*;
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.persistence.autoconfigure.EntityScan;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.support.TransactionTemplate;

/** Explicit local DEV operator action, disabled in normal test/CI runs. No SQL seeding. */
@SpringBootTest
@EntityScan(basePackages = {
    "io.github.alimbetov.voxprep.backend.asset.persistence",
    "io.github.alimbetov.voxprep.backend.catalogue.persistence",
    "io.github.alimbetov.voxprep.backend.content.localization",
    "io.github.alimbetov.voxprep.backend.content.persistence",
    "io.github.alimbetov.voxprep.backend.content.review",
    "io.github.alimbetov.voxprep.backend.installation.persistence",
    "io.github.alimbetov.voxprep.backend.publication.persistence",
    "io.github.alimbetov.voxprep.backend.tts.persistence"
})
@ActiveProfiles("dev")
@EnabledIfSystemProperty(named = "voxprep.local.tts.setup", matches = "true")
class LocalMacTtsModelSetupTest {
    @Autowired TtsVoiceRepository voices;
    @Autowired TtsVoiceModelRepository models;
    @Autowired TtsModelMaterializationService materialization;
    @Autowired TtsProvisioningLock lock;
    @Autowired org.springframework.transaction.PlatformTransactionManager transactions;

    @Test
    void provisionPinnedPublicDomainLjspeechThroughBackendServices() {
        var selector = new TtsModelSelector("en_US", "ljspeech", "medium");
        String revision = "a517d785c98755ae1bb6c1bffd48a83e10c2f36f";
        String base = "https://huggingface.co/rhasspy/piper-voices/resolve/" + revision
                + "/en/en_US/ljspeech/medium/en_US-ljspeech-medium.onnx";
        String modelSha = "6f52a751e2349abe7a76735eb09dc1875298c77ea2342ffd2fef79ff81b87f22";
        String configSha = "141d612cc0a95ed7efc1ca936b845c2364967f2e9217c5dbfcf69fc4d6c65860";
        var descriptor = new TtsModelCatalogGateway.ModelDescriptor("huggingface", "rhasspy/piper-voices",
                revision, "1.4.2", "piper-voices-" + revision, base, base + ".json", modelSha, configSha,
                "Public domain (LJ Speech Dataset)", "https://keithito.com/LJ-Speech-Dataset/");
        lock.withLock(selector.modelCode(), () -> new TransactionTemplate(transactions).execute(status -> {
            var voice = voices.findByCode(selector.voiceCode()).orElseGet(() -> voices.saveAndFlush(
                    new TtsVoiceEntity(selector.voiceCode(), "LJ Speech — local acceptance", "en-US",
                            "US", "female", "neutral", true)));
            var model = materialization.materialize(selector, descriptor);
            assertThat(model.getModelSha256()).isEqualTo(modelSha);
            assertThat(model.getConfigSha256()).isEqualTo(configSha);
            assertThat(model.getSourceRevision()).isEqualTo(revision);
            model.updateReviewMetadata(TtsVoiceModelStatus.ACTIVE, descriptor.licenseName(),
                    descriptor.licenseReference(), true, Instant.now());
            models.saveAndFlush(model);
            voice.selectDefaultModel(model);
            voices.saveAndFlush(voice);
            System.out.printf("A3_MODEL_READY id=%s code=%s model_sha256=%s config_sha256=%s%n",
                    model.getId(), model.getCode(), modelSha, configSha);
            return model.getId();
        }));
    }
}
