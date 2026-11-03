package io.github.alimbetov.voxprep.backend.learner.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CollectionAccessLevel;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.*;
import io.github.alimbetov.voxprep.backend.content.application.AssessmentDeliveryConfigurationService;
import io.github.alimbetov.voxprep.backend.content.persistence.*;
import io.github.alimbetov.voxprep.backend.installation.security.InstallationPrincipal;
import io.github.alimbetov.voxprep.backend.publication.application.PublicationCandidateManifestService;
import io.github.alimbetov.voxprep.backend.publication.application.PublicationPublisher;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationCandidateStatus;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateRepository;
import io.github.alimbetov.voxprep.backend.sharedkernel.*;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

/** Production DB wiring: explicit assessment config -> frozen release -> exact learner DTO. */
@ActiveProfiles("test")
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Transactional
class B7AssessmentDeliveryIntegrationTest {

    @Autowired private ContentRevisionRepository revisions;
    @Autowired private FileAssetRepository assets;
    @Autowired private VerticalRepository verticals;
    @Autowired private LearningGoalRepository goals;
    @Autowired private LearningTrackRepository tracks;
    @Autowired private LearningCollectionRepository collections;
    @Autowired private CollectionContentMemberRepository members;
    @Autowired private AssessmentDeliveryConfigurationService assessmentConfig;
    @Autowired private PublicationCandidateRepository candidateRepository;
    @Autowired private PublicationCandidateManifestService manifestService;
    @Autowired private PublicationPublisher publisher;
    @Autowired private LearnerWirePublicationService wire;
    @Autowired private LearnerExactPracticeTestService practiceTests;
    @Autowired private LearnerExactQuestionService questions;

    @AfterEach
    void clearSecurity() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void releasesFrozenExamWithExplicitPointsAndServesBothFlutterAssessmentDtos() {
        var question = revisions.saveAndFlush(new QuestionContentRevisionEntity(
                new BusinessCode("R3_Q_01"), new RevisionNumber(1),
                new Sha256Digest("c".repeat(64)),
                "Question", "Choose one", "A Java question",
                new CatalogueCode("GENERAL"), new CatalogueCode("B2"), 1,
                List.of(new CatalogueCode("GRAMMAR")), AvailabilityStatus.ACTIVE,
                "What is dependency injection?", "Separating construction from use.",
                List.of(new QuestionOptionEmbeddable("A", "Constructor injection", true),
                        new QuestionOptionEmbeddable("B", "Manual global state", false))));
        var test = revisions.saveAndFlush(new PracticeTestContentRevisionEntity(
                new BusinessCode("R3_TEST_01"), new RevisionNumber(1),
                new Sha256Digest("b".repeat(64)),
                "Java assessment", "Backend fundamentals", "Assess backend understanding",
                new CatalogueCode("GENERAL"), new CatalogueCode("B2"), 5,
                List.of(new CatalogueCode("GRAMMAR")), AvailabilityStatus.ACTIVE,
                "Choose the correct answer", 85, List.of(question.getId())));

        assessmentConfig.configure(test.getId(), "exam", List.of(3));
        approved(question);
        approved(test);

        var icon = assets.saveAndFlush(new FileAssetEntity(
                FileAssetKind.COVER_IMAGE, FileAssetStatus.READY,
                "voxprep-assets", "icons/r3-assessment.webp", "image/webp",
                42, "e".repeat(64)));
        var vertical = verticals.saveAndFlush(new VerticalEntity(
                new CatalogueCode("R3_CAREER"), new CatalogueCode("R3_TECH"),
                "Software", "Technical interviews", icon.getId().toString(),
                0, AvailabilityStatus.ACTIVE));
        var goal = goals.saveAndFlush(new LearningGoalEntity(
                new CatalogueCode("R3_GOAL"), vertical, "Interview",
                "Interview preparation", 0, AvailabilityStatus.ACTIVE));
        var track = tracks.saveAndFlush(new LearningTrackEntity(
                new CatalogueCode("R3_TRACK"), goal, "Java backend", "Interview skills",
                new CatalogueCode("B2"), null, 0, AvailabilityStatus.ACTIVE));
        var collection = collections.saveAndFlush(new LearningCollectionEntity(
                new CatalogueCode("R3_FREE"), track, "Free assessment", "First assessment",
                CollectionAccessLevel.FREE, 0, AvailabilityStatus.ACTIVE));
        members.saveAndFlush(new CollectionContentMemberEntity(collection, 0, test));

        var candidate = candidateRepository.saveAndFlush(
                new PublicationCandidateEntity(PublicationCandidateStatus.DRAFT));
        var questionRef = new PublicationExactContentRef(question.getIdentity(), question.getChecksum());
        var testRef = new PublicationExactContentRef(test.getIdentity(), test.getChecksum());
        var validation = manifestService.validateAndFreeze(candidate.getId(),
                List.of(questionRef, testRef), Instant.parse("2026-11-03T09:05:00Z"));
        assertThat(validation.valid()).isTrue();
        var release = publisher.publish(candidate.getId(), Instant.parse("2026-11-03T09:10:00Z"));

        assertThat((List<?>) wire.root().body().get("practiceTests")).hasSize(1);
        assertThat((List<?>) wire.catalogue("learning-collections",
                (int) release.contentVersion()).body().get("items")).hasSize(1);

        var exactTest = practiceTests.get("R3_TEST_01", 1);
        assertThat(exactTest.mode()).isEqualTo("exam");
        assertThat(exactTest.passingScoreBasisPoints()).isEqualTo(8500);
        assertThat(exactTest.questionRefs()).hasSize(1);
        assertThat(exactTest.questionRefs().get(0).points()).isEqualTo(3);
        assertThat(exactTest.questionRefs().get(0).question().questionCode()).isEqualTo("R3_Q_01");

        SecurityContextHolder.getContext().setAuthentication(
                UsernamePasswordAuthenticationToken.authenticated(
                        new InstallationPrincipal(UUID.fromString("11111111-1111-4111-8111-111111111111")),
                        "opaque-token", List.of()));
        var exactQuestion = questions.get("R3_Q_01", 1);
        assertThat(exactQuestion.body().correctOptionIndex()).isEqualTo(0);
        assertThat(exactQuestion.body().options()).containsExactly(
                "Constructor injection", "Manual global state");
        assertThatThrownBy(() -> assessmentConfig.configure(
                test.getId(), "learn", List.of(1)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("immutable");
    }

    private void approved(ContentRevisionEntity revision) {
        revision.markReadyForAudio();
        revisions.saveAndFlush(revision);
        revision.markReadyForReview();
        revisions.saveAndFlush(revision);
        revision.approve(Instant.parse("2026-11-03T09:00:00Z"));
        revisions.saveAndFlush(revision);
    }
}
