package io.github.alimbetov.voxprep.backend.learner;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.alimbetov.voxprep.backend.asset.application.ContentAssetBindingService;
import io.github.alimbetov.voxprep.backend.asset.application.FileAssetIngestService;
import io.github.alimbetov.voxprep.backend.asset.domain.ContentAssetRole;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CollectionAccessLevel;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.*;
import io.github.alimbetov.voxprep.backend.content.application.AssessmentDeliveryConfigurationService;
import io.github.alimbetov.voxprep.backend.content.persistence.*;
import io.github.alimbetov.voxprep.backend.publication.application.PublicationCandidateManifestService;
import io.github.alimbetov.voxprep.backend.publication.application.PublicationPublisher;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationCandidateStatus;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateRepository;
import io.github.alimbetov.voxprep.backend.sharedkernel.*;
import java.io.File;
import java.time.Instant;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

/**
 * A1 system test: real committed PostgreSQL publication + live Spring MVC HTTP
 * + real RustFS bytes + production Flutter decoders/Drift/restart. No MockMvc,
 * mock HTTP handler, or synthetic publication JSON is on this acceptance path.
 *
 * Opt in with -Dvoxprep.a1.enabled=true and run from the dedicated CI job.
 * The test process owns the live server while the Flutter subprocess executes.
 */
@ActiveProfiles("test")
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@EnabledIfSystemProperty(named = "voxprep.a1.enabled", matches = "true")
class A1RealBackendFlutterAcceptanceTest {

    private static final Instant APPROVED = Instant.parse("2026-11-03T09:00:00Z");
    private static final Instant PUBLISHED = Instant.parse("2026-11-03T10:00:00Z");
    private static final String FREE_CODE = "A1_FREE_PHRASE";
    private static final String FULL_CODE = "A1_FULL_PHRASE";
    private static final String TEST_CODE = "A1_FREE_EXAM";
    private static final String QUESTION_CODE = "A1_EXAM_QUESTION";

    // A valid 1x1 PNG. The backing RustFS object is written through production ingest.
    private static final String ICON_PNG =
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/5a0AAAAASUVORK5CYII=";

    @Value("${local.server.port}")
    private int serverPort;

    @Autowired private ContentRevisionRepository revisions;
    @Autowired private FileAssetIngestService ingest;
    @Autowired private ContentAssetBindingService binding;
    @Autowired private VerticalRepository verticals;
    @Autowired private LearningGoalRepository goals;
    @Autowired private LearningTrackRepository tracks;
    @Autowired private LearningCollectionRepository collections;
    @Autowired private CollectionContentMemberRepository members;
    @Autowired private AssessmentDeliveryConfigurationService assessmentConfig;
    @Autowired private PublicationCandidateRepository candidates;
    @Autowired private PublicationCandidateManifestService manifests;
    @Autowired private PublicationPublisher publisher;

    @Test
    void flutterSynchronizesActualMixedFreeFullPublishedRelease() throws Exception {
        var icon = ingest.ingest(new FileAssetIngestService.IngestCommand(
                FileAssetKind.COVER_IMAGE,
                "voxprep-assets",
                "acceptance/a1/real-backend-icon.png",
                "image/png",
                Map.of(),
                Base64.getDecoder().decode(ICON_PNG)));

        var free = phrase(FREE_CODE, "Interview introduction",
                "Could you introduce yourself?");
        var full = phrase(FULL_CODE, "Advanced interview strategies",
                "What was your hardest architecture decision?");
        binding.bind(free.getId(), ContentAssetRole.COVER_IMAGE, icon.getId(), null);

        var question = revisions.saveAndFlush(new QuestionContentRevisionEntity(
                new BusinessCode(QUESTION_CODE), new RevisionNumber(1),
                new Sha256Digest("a".repeat(64)),
                "Dependency injection", "Choose the best answer", "Java basics",
                new CatalogueCode("GENERAL"), new CatalogueCode("B1"), 1,
                List.of(new CatalogueCode("GRAMMAR")), AvailabilityStatus.ACTIVE,
                "What is dependency injection?", "Decoupling construction from use.",
                List.of(
                        new QuestionOptionEmbeddable("A", "Pass dependencies through a constructor", true),
                        new QuestionOptionEmbeddable("B", "Use global mutable state", false))));
        var test = revisions.saveAndFlush(new PracticeTestContentRevisionEntity(
                new BusinessCode(TEST_CODE), new RevisionNumber(1),
                new Sha256Digest("b".repeat(64)),
                "Backend basics", "First assessment", "Knowledge check",
                new CatalogueCode("GENERAL"), new CatalogueCode("B1"), 3,
                List.of(new CatalogueCode("GRAMMAR")), AvailabilityStatus.ACTIVE,
                "Choose one option", 80, List.of(question.getId())));
        assessmentConfig.configure(test.getId(), "exam", List.of(3));

        for (var revision : List.of(free, full, question, test)) {
            revision.markReadyForAudio();
            revisions.saveAndFlush(revision);
            revision.markReadyForReview();
            revisions.saveAndFlush(revision);
            revision.approve(APPROVED);
            revisions.saveAndFlush(revision);
        }

        var vertical = verticals.saveAndFlush(new VerticalEntity(
                new CatalogueCode("A1_CAREER"), new CatalogueCode("A1_TECH"),
                "Career English", "Technical interviews", icon.getId().toString(),
                0, AvailabilityStatus.ACTIVE));
        var goal = goals.saveAndFlush(new LearningGoalEntity(
                new CatalogueCode("A1_INTERVIEW"), vertical,
                "Interview skills", "Prepare for interviews", 0, AvailabilityStatus.ACTIVE));
        var track = tracks.saveAndFlush(new LearningTrackEntity(
                new CatalogueCode("A1_JAVA"), goal,
                "Java developer", "Technical English", new CatalogueCode("B1"), null,
                0, AvailabilityStatus.ACTIVE));
        var freeCollection = collections.saveAndFlush(new LearningCollectionEntity(
                new CatalogueCode("A1_FREE"), track, "Start here",
                "First free block", CollectionAccessLevel.FREE,
                0, AvailabilityStatus.ACTIVE));
        var fullCollection = collections.saveAndFlush(new LearningCollectionEntity(
                new CatalogueCode("A1_FULL"), track, "Advanced",
                "Premium block", CollectionAccessLevel.FULL,
                1, AvailabilityStatus.ACTIVE));
        members.saveAndFlush(new CollectionContentMemberEntity(freeCollection, 0, free));
        members.saveAndFlush(new CollectionContentMemberEntity(freeCollection, 1, test));
        members.saveAndFlush(new CollectionContentMemberEntity(fullCollection, 0, full));

        var candidate = candidates.saveAndFlush(new PublicationCandidateEntity(
                PublicationCandidateStatus.DRAFT));
        var refs = List.of(
                new PublicationExactContentRef(free.getIdentity(), free.getChecksum()),
                new PublicationExactContentRef(full.getIdentity(), full.getChecksum()),
                new PublicationExactContentRef(test.getIdentity(), test.getChecksum()),
                new PublicationExactContentRef(question.getIdentity(), question.getChecksum()));
        var validation = manifests.validateAndFreeze(candidate.getId(), refs, APPROVED.plusSeconds(600));
        assertThat(validation.valid()).as("Publication fixture validation: %s", validation.issues()).isTrue();
        var publication = publisher.publish(candidate.getId(), PUBLISHED);
        assertThat(publication.replayed()).isFalse();

        var flutterDirectory = new File(System.getProperty(
                "voxprep.a1.flutter.dir", "../mobile/careerspeak_app"));
        assertThat(new File(flutterDirectory, "pubspec.yaml")).isFile();

        var command = List.of(
                "flutter", "test",
                "--dart-define=A1_REAL_BACKEND=true",
                "--dart-define=A1_API_BASE_URL=http://127.0.0.1:" + serverPort,
                "--dart-define=A1_FREE_CODE=" + FREE_CODE,
                "--dart-define=A1_FULL_CODE=" + FULL_CODE,
                "--dart-define=A1_TEST_CODE=" + TEST_CODE,
                "--dart-define=A1_QUESTION_CODE=" + QUESTION_CODE,
                "--reporter=expanded",
                "test/acceptance/a1_real_backend_flutter_test.dart");

        Process process = new ProcessBuilder(command)
                .directory(flutterDirectory)
                .redirectErrorStream(true)
                .inheritIO()
                .start();
        boolean completed = process.waitFor(8, TimeUnit.MINUTES);
        if (!completed) {
            process.destroyForcibly();
        }
        assertThat(completed).as("Flutter A1 exceeded its bounded timeout").isTrue();
        assertThat(process.exitValue()).as("Real Flutter HTTP/Drift A1 acceptance").isZero();
    }

    private PhraseContentRevisionEntity phrase(String code, String title, String phrase) {
        return revisions.saveAndFlush(new PhraseContentRevisionEntity(
                new BusinessCode(code), new RevisionNumber(1),
                new Sha256Digest(code.equals(FREE_CODE) ? "c".repeat(64) : "d".repeat(64)),
                title, "CareerSpeak", "Live A1 test content",
                new CatalogueCode("GENERAL"), new CatalogueCode("B1"), 2,
                List.of(new CatalogueCode("SPEAKING")), AvailabilityStatus.ACTIVE,
                phrase, "Interview preparation", List.of(phrase + " Example.")));
    }
}
