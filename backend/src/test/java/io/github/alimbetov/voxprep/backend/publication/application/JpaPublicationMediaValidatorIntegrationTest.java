package io.github.alimbetov.voxprep.backend.publication.application;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.PhraseContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.ShadowingContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.ShadowingSegmentEmbeddable;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import io.github.alimbetov.voxprep.backend.tts.application.TtsJobLeaseService;
import io.github.alimbetov.voxprep.backend.tts.application.TtsJobPreparationService;
import io.github.alimbetov.voxprep.backend.tts.application.TtsOutputFinalizationService;
import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioRole;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsVoiceModelStatus;
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
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@ActiveProfiles("test")
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Transactional
class JpaPublicationMediaValidatorIntegrationTest {

    private static final String SOURCE_PROVIDER = "huggingface";
    private static final String SOURCE_REPOSITORY = "rhasspy/piper-voices";
    private static final String SOURCE_REVISION = "a517d785c98755ae1bb6c1bffd48a83e10c2f36f";

    @Autowired private PublicationMediaValidator mediaValidator;
    @Autowired private ContentRevisionRepository contentRevisionRepository;
    @Autowired private FileAssetRepository assetRepository;
    @Autowired private TtsVoiceRepository voiceRepository;
    @Autowired private TtsVoiceModelRepository modelRepository;
    @Autowired private TtsJobPreparationService preparationService;
    @Autowired private TtsJobLeaseService leaseService;
    @Autowired private TtsOutputFinalizationService outputService;

    @Test
    void missingRecommendedAudioWarnsButMissingRequiredAudioBlocks() {
        var phrase = phrase("R5_WARN", '1');
        var shadowing = shadowing("R5_REQUIRED", '2');

        var phraseIssues = mediaValidator.validate(ref(phrase));
        var shadowingIssues = mediaValidator.validate(ref(shadowing));

        assertThat(phraseIssues)
                .extracting(PublicationValidationIssue::severity, PublicationValidationIssue::code)
                .containsExactly(org.assertj.core.groups.Tuple.tuple(
                        PublicationValidationSeverity.WARNING,
                        PublicationValidationCode.MISSING_RECOMMENDED_AUDIO));
        assertThat(shadowingIssues)
                .extracting(PublicationValidationIssue::severity, PublicationValidationIssue::code)
                .containsExactly(org.assertj.core.groups.Tuple.tuple(
                        PublicationValidationSeverity.ERROR,
                        PublicationValidationCode.MISSING_REQUIRED_AUDIO));
    }

    @Test
    void finalizedAudioIsReadyThenBecomesStaleAfterDraftTextChanges() {
        var revision = phrase("R5_STALE", '3');
        var model = activeModel("r5-stale");

        var preparation = preparationService.prepare(
                revision.getId(),
                ContentAudioRole.PRONUNCIATION,
                "en-US",
                model.getCode());
        var claim = leaseService.claimNextForWorker("r5-worker", Duration.ofMinutes(5)).orElseThrow();
        byte[] mp3 = "r5-qualified-mp3".getBytes(StandardCharsets.UTF_8);
        var finalized = outputService.finalizeOutput(new TtsOutputFinalizationService.OutputUpload(
                preparation.jobId(),
                "r5-worker",
                preparation.fileId(),
                claim.leaseToken(),
                preparation.fingerprint(),
                model.getId(),
                TtsOutputFinalizationService.AUDIO_PROFILE,
                sha256(mp3),
                mp3.length,
                1000L,
                TtsOutputFinalizationService.CONTENT_TYPE,
                mp3));

        assertThat(finalized).isEqualTo(TtsOutputFinalizationService.FinalizationResult.CREATED);
        assertThat(mediaValidator.validate(ref(revision))).isEmpty();

        revision.replaceDraftBody(
                "A changed phrase that invalidates prior audio.",
                "Usage",
                List.of("Example"),
                new Sha256Digest(String.valueOf('4').repeat(64)));
        contentRevisionRepository.saveAndFlush(revision);

        assertThat(mediaValidator.validate(ref(revision)))
                .extracting(PublicationValidationIssue::severity, PublicationValidationIssue::code)
                .containsExactly(org.assertj.core.groups.Tuple.tuple(
                        PublicationValidationSeverity.ERROR,
                        PublicationValidationCode.STALE_AUDIO));
    }

    private PhraseContentRevisionEntity phrase(String code, char checksumChar) {
        return contentRevisionRepository.saveAndFlush(new PhraseContentRevisionEntity(
                new BusinessCode(code),
                new RevisionNumber(1),
                new Sha256Digest(String.valueOf(checksumChar).repeat(64)),
                "Title",
                "Subtitle",
                "Description",
                new CatalogueCode("GENERAL"),
                new CatalogueCode("B1"),
                1,
                List.of(new CatalogueCode("SPEAKING")),
                AvailabilityStatus.ACTIVE,
                "Could you tell me more?",
                "Usage",
                List.of("Example")));
    }

    private ShadowingContentRevisionEntity shadowing(String code, char checksumChar) {
        return contentRevisionRepository.saveAndFlush(new ShadowingContentRevisionEntity(
                new BusinessCode(code),
                new RevisionNumber(1),
                new Sha256Digest(String.valueOf(checksumChar).repeat(64)),
                "Title",
                "Subtitle",
                "Description",
                new CatalogueCode("GENERAL"),
                new CatalogueCode("B1"),
                1,
                List.of(new CatalogueCode("LISTENING")),
                AvailabilityStatus.ACTIVE,
                "Good morning. Thank you for inviting me.",
                List.of(new ShadowingSegmentEmbeddable("Good morning.", 0, 1000))));
    }

    private TtsVoiceModelEntity activeModel(String suffix) {
        var voice = voiceRepository.saveAndFlush(new TtsVoiceEntity(
                "voice-" + suffix,
                "US English",
                "en-US",
                "US",
                "FEMALE",
                "NEUTRAL",
                true));
        var assets = TtsTestAssets.createModelAssets(assetRepository, suffix, 'a', 'b');
        return modelRepository.saveAndFlush(new TtsVoiceModelEntity(
                "model-" + suffix,
                voice,
                TtsEngine.PIPER,
                "1.3.0",
                "r5-v1",
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
    }

    private static PublicationExactContentRef ref(io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionEntity revision) {
        return new PublicationExactContentRef(revision.getIdentity(), revision.getChecksum());
    }

    private static String sha256(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (Exception exception) {
            throw new IllegalStateException(exception);
        }
    }
}
