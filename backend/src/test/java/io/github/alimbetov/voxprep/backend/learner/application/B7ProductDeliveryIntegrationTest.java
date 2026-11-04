package io.github.alimbetov.voxprep.backend.learner.application;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.alimbetov.voxprep.backend.asset.application.ContentAssetBindingService;
import io.github.alimbetov.voxprep.backend.asset.domain.ContentAssetRole;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CollectionAccessLevel;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.VerticalEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.VerticalRepository;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningGoalEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningGoalRepository;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningTrackEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningTrackRepository;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningCollectionEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningCollectionRepository;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.CollectionContentMemberEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.CollectionContentMemberRepository;
import io.github.alimbetov.voxprep.backend.content.application.ContentRevisionSnapshot;
import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.PhraseContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.publication.application.PublicationCandidateManifestService;
import io.github.alimbetov.voxprep.backend.publication.application.PublicationPublisher;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationCandidateStatus;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateRepository;
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
class B7ProductDeliveryIntegrationTest {

    private static final String SOURCE_PROVIDER = "huggingface";
    private static final String SOURCE_REPOSITORY = "rhasspy/piper-voices";
    private static final String SOURCE_REVISION = "a517d785c98755ae1bb6c1bffd48a83e10c2f36f";

    @Autowired private ContentRevisionRepository contentRevisionRepository;
    @Autowired private FileAssetRepository assetRepository;
    @Autowired private VerticalRepository verticalRepository;
    @Autowired private LearningGoalRepository goalRepository;
    @Autowired private LearningTrackRepository trackRepository;
    @Autowired private LearningCollectionRepository collectionRepository;
    @Autowired private CollectionContentMemberRepository memberRepository;
    @Autowired private LearnerWirePublicationService wirePublicationService;
    @Autowired private LearnerFrozenAccessResolver frozenAccessResolver;
    @Autowired private ContentAssetBindingService bindingService;
    @Autowired private TtsVoiceRepository voiceRepository;
    @Autowired private TtsVoiceModelRepository modelRepository;
    @Autowired private TtsJobPreparationService preparationService;
    @Autowired private TtsJobLeaseService leaseService;
    @Autowired private TtsOutputFinalizationService outputService;
    @Autowired private PublicationCandidateRepository candidateRepository;
    @Autowired private PublicationCandidateManifestService manifestService;
    @Autowired private PublicationPublisher publisher;
    @Autowired private CurrentPublicationResolver currentPublicationResolver;
    @Autowired private LearnerContentService learnerContentService;
    @Autowired private LearnerPublishedMediaService learnerMediaService;

    @Test
    void exactRevisionFlowsThroughTtsPublicationCurrentAndLearnerMedia() {
        var revision = contentRevisionRepository.saveAndFlush(new PhraseContentRevisionEntity(
                new BusinessCode("R6_PHRASE"),
                new RevisionNumber(1),
                new Sha256Digest(String.valueOf('6').repeat(64)),
                "Interview phrase",
                "Learner subtitle",
                "Learner description",
                new CatalogueCode("GENERAL"),
                new CatalogueCode("B1"),
                2,
                List.of(new CatalogueCode("SPEAKING")),
                AvailabilityStatus.ACTIVE,
                "Could you tell me more about your experience?",
                "Interview follow-up",
                List.of("Could you tell me more about your last project?")));
        var model = activeModel("r6-product");

        var prepared = preparationService.prepare(
                revision.getId(),
                ContentAudioRole.PRONUNCIATION,
                "en-US",
                model.getCode());
        var claim = leaseService.claimNextForWorker("r6-worker", Duration.ofMinutes(5)).orElseThrow();
        byte[] mp3 = "r6-product-qualified-mp3".getBytes(StandardCharsets.UTF_8);
        var finalized = outputService.finalizeOutput(new TtsOutputFinalizationService.OutputUpload(
                prepared.jobId(),
                "r6-worker",
                prepared.fileId(),
                claim.leaseToken(),
                prepared.fingerprint(),
                model.getId(),
                TtsOutputFinalizationService.AUDIO_PROFILE,
                sha256(mp3),
                mp3.length,
                1200L,
                TtsOutputFinalizationService.CONTENT_TYPE,
                mp3));
        assertThat(finalized).isEqualTo(TtsOutputFinalizationService.FinalizationResult.CREATED);

        var cover = assetRepository.saveAndFlush(new FileAssetEntity(
                FileAssetKind.COVER_IMAGE,
                FileAssetStatus.READY,
                "voxprep-assets",
                "content/r6/cover.webp",
                "image/webp",
                42,
                String.valueOf('8').repeat(64)));
        bindingService.bind(revision.getId(), ContentAssetRole.COVER_IMAGE, cover.getId(), null);

        revision.markReadyForAudio();
        contentRevisionRepository.saveAndFlush(revision);
        revision.markReadyForReview();
        contentRevisionRepository.saveAndFlush(revision);
        revision.approve(Instant.parse("2026-11-03T14:00:00Z"));
        contentRevisionRepository.saveAndFlush(revision);

        // The real Flutter publication contract requires a stable, ordered
        // collection membership. A bare content revision is not a learner pack.
        var vertical = verticalRepository.saveAndFlush(new VerticalEntity(
                new CatalogueCode("R6_CAREER"), new CatalogueCode("R6_TECH"),
                "Career", "Interview preparation", cover.getId().toString(), 0, AvailabilityStatus.ACTIVE));
        var goal = goalRepository.saveAndFlush(new LearningGoalEntity(
                new CatalogueCode("R6_INTERVIEW"), vertical,
                "Interviews", "Interview goal", 0, AvailabilityStatus.ACTIVE));
        var track = trackRepository.saveAndFlush(new LearningTrackEntity(
                new CatalogueCode("R6_ENGLISH"), goal, "English interview",
                "Interview speaking", new CatalogueCode("B1"), null,
                0, AvailabilityStatus.ACTIVE));
        var collection = collectionRepository.saveAndFlush(new LearningCollectionEntity(
                new CatalogueCode("R6_FREE"), track, "First block",
                "Free opening lesson", CollectionAccessLevel.FREE,
                0, AvailabilityStatus.ACTIVE));
        memberRepository.saveAndFlush(new CollectionContentMemberEntity(collection, 0, revision));

        PublicationExactContentRef ref = new PublicationExactContentRef(revision.getIdentity(), revision.getChecksum());
        PublicationCandidateEntity candidate = candidateRepository.saveAndFlush(
                new PublicationCandidateEntity(PublicationCandidateStatus.DRAFT));
        var validation = manifestService.validateAndFreeze(
                candidate.getId(),
                List.of(ref),
                Instant.parse("2026-11-03T14:05:00Z"));
        assertThat(validation.valid()).isTrue();
        assertThat(validation.hasWarnings()).isFalse();

        var published = publisher.publish(candidate.getId(), Instant.parse("2026-11-03T14:10:00Z"));
        assertThat(published.replayed()).isFalse();

        var current = currentPublicationResolver.resolve();
        assertThat(current.contentVersion()).isEqualTo(published.contentVersion());
        assertThat(current.refs()).containsExactly(ref);

        // No mocks: exact release-scoped wire root, pack and collection JSON
        // are available from the same publisher transaction.
        var root = wirePublicationService.root();
        assertThat(root.body()).containsEntry("schemaVersion", 2);
        assertThat((List<?>) root.body().get("catalogues")).hasSize(6);
        var pack = wirePublicationService.pack("R6_FREE", "canonical",
                (int) published.contentVersion());
        assertThat((List<?>) pack.body().get("contents")).hasSize(1);
        var collectionSnapshot = wirePublicationService.catalogue(
                "learning-collections", (int) published.contentVersion());
        assertThat((List<?>) collectionSnapshot.body().get("items")).hasSize(1);

        // Post-publication authoring changes must NOT rewrite the FREE/FULL
        // decision captured in the immutable learning-collections document.
        assertThat(frozenAccessResolver.requiresFull(ref, published.contentVersion())).isFalse();
        collection.updateDetails(track, "First block", "Updated authoring metadata",
                CollectionAccessLevel.FULL, 0, AvailabilityStatus.ACTIVE);
        collectionRepository.saveAndFlush(collection);
        assertThat(frozenAccessResolver.requiresFull(ref, published.contentVersion())).isFalse();

        var content = learnerContentService.get("phrase", "R6_PHRASE");
        assertThat(content.contentVersion()).isEqualTo(published.contentVersion());
        assertThat(content.contentCode()).isEqualTo("R6_PHRASE");
        assertThat(content.body()).isInstanceOf(ContentRevisionSnapshot.PhraseBody.class);
        assertThat(((ContentRevisionSnapshot.PhraseBody) content.body()).phrase())
                .isEqualTo("Could you tell me more about your experience?");

        var media = learnerMediaService.listMedia("phrase", "R6_PHRASE");
        assertThat(media).extracting(LearnerPublishedMediaService.MediaAssetSnapshot::role)
                .containsExactly("coverImage", "pronunciation");
        assertThat(media).extracting(LearnerPublishedMediaService.MediaAssetSnapshot::kind)
                .containsExactly("COVER_IMAGE", "TTS_AUDIO");

        var frozen = contentRevisionRepository.findById(revision.getId()).orElseThrow();
        assertThat(frozen.getLifecycle()).isEqualTo(ContentLifecycleStatus.PUBLISHED);
        assertThat(frozen.getPublishedAt()).isEqualTo(Instant.parse("2026-11-03T14:10:00Z"));
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
                "r6-v1",
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

    private static String sha256(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (Exception exception) {
            throw new IllegalStateException(exception);
        }
    }
}
