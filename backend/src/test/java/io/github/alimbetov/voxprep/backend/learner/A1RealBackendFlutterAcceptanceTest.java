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
import java.util.UUID;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

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

    @Value("${voxprep.security.admin.username}")
    private String adminUsername;

    @Value("${voxprep.security.admin.password}")
    private String adminPassword;

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
    @Autowired private PlatformTransactionManager transactionManager;

    @Test
    void flutterSynchronizesActualMixedFreeFullPublishedRelease() throws Exception {
        // Real HTTP creation: initial FREE revision is no longer a JPA fixture.
        UUID authoredId = new R5AdminHttpPublicationWorkflow(serverPort, adminUsername, adminPassword)
                .createPhrase(FREE_CODE, "Interview introduction", "Could you introduce yourself?");
        var adminPublication = new java.util.concurrent.atomic.AtomicReference<PublicationHttpFixture>();
        new TransactionTemplate(transactionManager).executeWithoutResult(status -> {
        var icon = ingest.ingest(new FileAssetIngestService.IngestCommand(
                FileAssetKind.COVER_IMAGE,
                "voxprep-assets",
                "acceptance/a1/real-backend-icon.png",
                "image/png",
                Map.of(),
                Base64.getDecoder().decode(ICON_PNG)));

        var free = revisions.findById(authoredId).orElseThrow();
        var full = phrase(FULL_CODE, "Advanced interview strategies",
                "What was your hardest architecture decision?");

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

        // The FREE draft is reviewed via real Content Studio HTTP after image binding.
        for (var revision : List.of(full, question, test)) {
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
        var primaryMember = members.saveAndFlush(new CollectionContentMemberEntity(freeCollection, 0, free));
        members.saveAndFlush(new CollectionContentMemberEntity(freeCollection, 1, test));
        members.saveAndFlush(new CollectionContentMemberEntity(fullCollection, 0, full));

        var candidate = candidates.saveAndFlush(new PublicationCandidateEntity(
                PublicationCandidateStatus.DRAFT));
        var refs = List.of(
                new PublicationExactContentRef(free.getIdentity(), free.getChecksum()),
                new PublicationExactContentRef(full.getIdentity(), full.getChecksum()),
                new PublicationExactContentRef(test.getIdentity(), test.getChecksum()),
                new PublicationExactContentRef(question.getIdentity(), question.getChecksum()));
        adminPublication.set(new PublicationHttpFixture(free.getId(), icon.getId(), candidate.getId(),
                freeCollection.getId(), primaryMember.getId(), refs));
        }); // Commit fixture before ADMIN HTTP binding and publish (separate transaction).

        var fixture = adminPublication.get();
        assertThat(fixture).isNotNull();
        new R5AdminHttpPublicationWorkflow(serverPort, adminUsername, adminPassword)
                .bindAndPublish(fixture.revisionId(), fixture.assetId(),
                        fixture.candidateId(), fixture.refs());
        // Flutter must consume the publication produced by Content Studio HTTP, not
        // by a direct test call to PublicationPublisher or ContentAssetBindingService.

        var flutterDirectory = new File(System.getProperty(
                "voxprep.a1.flutter.dir", "../mobile/careerspeak_app"));
        assertThat(new File(flutterDirectory, "pubspec.yaml")).isFile();

        var r5Signals = java.nio.file.Files.createTempDirectory("voxprep-r5-n2-");
        var command = List.of(
                "flutter", "test",
                "--dart-define=A1_REAL_BACKEND=true",
                "--dart-define=A1_API_BASE_URL=http://127.0.0.1:" + serverPort,
                "--dart-define=A1_FREE_CODE=" + FREE_CODE,
                "--dart-define=A1_FULL_CODE=" + FULL_CODE,
                "--dart-define=A1_TEST_CODE=" + TEST_CODE,
                "--dart-define=A1_QUESTION_CODE=" + QUESTION_CODE,
                "--dart-define=A1_R5_CONTROL_DIR=" + r5Signals.toAbsolutePath(),
                "--reporter=expanded",
                "test/acceptance/a1_real_backend_flutter_test.dart");

        // On the *same* Flutter process and SQLite file, publish N+1 only
        // after the learner has fully committed and marked N ready.
        Thread upgrade = Thread.ofVirtual().start(() -> {
            try {
                var started = System.nanoTime();
                var ready = r5Signals.resolve("n1-ready");
                while (!java.nio.file.Files.exists(ready)) {
                    if (java.time.Duration.ofNanos(System.nanoTime() - started).toSeconds() > 150) {
                        throw new IllegalStateException("Flutter did not signal N1-ready");
                    }
                    Thread.sleep(100);
                }
                new R5AdminHttpPublicationWorkflow(serverPort, adminUsername, adminPassword)
                        .reviseAndPublish(fixture.revisionId(), fixture.assetId(),
                                fixture.collectionId(), fixture.memberId(), fixture.refs(),
                                id -> {
                                    var revision = revisions.findById(id).orElseThrow();
                                    return new PublicationExactContentRef(revision.getIdentity(), revision.getChecksum());
                                });
                java.nio.file.Files.writeString(r5Signals.resolve("n2-ready"), "published");
            } catch (Exception exception) {
                try {
                    java.nio.file.Files.writeString(r5Signals.resolve("n2-error"),
                            exception.getClass().getSimpleName() + ": " + exception.getMessage());
                } catch (java.io.IOException ignored) {
                    // Flutter's bounded wait still fails deterministically.
                }
            }
        });

        Process process = new ProcessBuilder(command)
                .directory(flutterDirectory)
                .redirectErrorStream(true)
                .start();
        // Capture child diagnostics rather than inheriting JVM stdout, which
        // corrupts the Maven Surefire wire protocol and hides Flutter failures.
        var output = new StringBuilder();
        Thread drain = Thread.ofVirtual().start(() -> {
            try (var reader = new java.io.BufferedReader(
                    new java.io.InputStreamReader(
                            process.getInputStream(), java.nio.charset.StandardCharsets.UTF_8))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    synchronized (output) {
                        if (output.length() < 100_000) {
                            output.append(line).append('\n');
                        }
                    }
                }
            } catch (java.io.IOException exception) {
                synchronized (output) {
                    output.append("Flutter log capture failed: ").append(exception.getMessage());
                }
            }
        });
        boolean completed = process.waitFor(8, TimeUnit.MINUTES);
        if (!completed) process.destroyForcibly();
        drain.join(10_000);
        upgrade.join(10_000);
        assertThat(completed).as("Flutter A1 exceeded timeout; output:\n%s", output).isTrue();
        assertThat(process.exitValue()).as("Real Flutter HTTP/Drift A1 acceptance:\n%s", output).isZero();
        assertThat(output.toString()).contains("A1_REAL_BACKEND_ACCEPTED");
        assertThat(java.nio.file.Files.exists(r5Signals.resolve("n2-ready")))
                .as("R5 N+1 publication must complete").isTrue();
    }

    private record PublicationHttpFixture(UUID revisionId, UUID assetId, UUID candidateId,
            UUID collectionId, UUID memberId, List<PublicationExactContentRef> refs) {}

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
