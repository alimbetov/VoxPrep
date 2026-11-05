package io.github.alimbetov.voxprep.backend.learner;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.alimbetov.voxprep.backend.asset.application.FileAssetIngestService;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningCollectionRepository;
import io.github.alimbetov.voxprep.backend.content.application.AssessmentDeliveryConfigurationService;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import java.io.File;
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
    @Autowired private LearningCollectionRepository collections;
    @Autowired private AssessmentDeliveryConfigurationService assessmentConfig;

    @Test
    void flutterSynchronizesActualMixedFreeFullPublishedRelease() throws Exception {
        // All source content revisions and catalogue hierarchy are created over
        // authenticated ADMIN HTTP, including immutable publication candidates.
        // JPA here is read-only identity resolution, not a shortcut for writes.
        var browser = new R5AdminHttpPublicationWorkflow(serverPort, adminUsername, adminPassword);
        UUID authoredId = browser.createPhrase(FREE_CODE, "Interview introduction",
                "Could you introduce yourself?");
        UUID fullId = browser.createPhrase(FULL_CODE, "Advanced interview strategies",
                "What was your hardest architecture decision?");
        UUID questionId = browser.createQuestion(QUESTION_CODE);
        UUID practiceTestId = browser.createPracticeTest(TEST_CODE, questionId);
        // Only storage ingestion and assessment scoring configuration use
        // backend application services; neither creates catalogue/membership rows.
        var icon = ingest.ingest(new FileAssetIngestService.IngestCommand(
                FileAssetKind.COVER_IMAGE, "voxprep-assets",
                "acceptance/a1/real-backend-icon.png", "image/png", Map.of(),
                Base64.getDecoder().decode(ICON_PNG)));
        assessmentConfig.configure(practiceTestId, "exam", List.of(3));

        // Real ADMIN HTTP creates the entire catalogue graph.
        browser.createCatalogue(icon.getId());
        browser.bindDraftImage(authoredId, icon.getId());
        browser.approveDraft(authoredId);
        browser.approveDraft(fullId);
        browser.approveDraft(questionId);
        browser.approveDraft(practiceTestId);

        UUID freeCollectionId = collections.findByCode(new CatalogueCode("A1_FREE"))
                .orElseThrow().getId();
        UUID fullCollectionId = collections.findByCode(new CatalogueCode("A1_FULL"))
                .orElseThrow().getId();
        // Read-only repository lookups resolve IDs created by the actual MVC.
        // The only writes to collection membership are CSRF-protected HTTP.
        UUID primaryMemberId = browser.appendMember(freeCollectionId, authoredId);
        browser.appendMember(freeCollectionId, practiceTestId);
        browser.appendMember(fullCollectionId, fullId);

        var refs = List.of(authoredId, fullId, practiceTestId, questionId).stream()
                .map(id -> revisions.findById(id).orElseThrow())
                .map(revision -> new PublicationExactContentRef(
                        revision.getIdentity(), revision.getChecksum()))
                .toList();
        var fixture = new PublicationHttpFixture(authoredId, icon.getId(),
                browser.createCandidate(), freeCollectionId, primaryMemberId, refs);
        browser.bindAndPublish(fixture.revisionId(), fixture.assetId(),
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

        // Preserve real Flutter/HTTP evidence outside the temporary handshake
        // folder so CI can publish an auditable artifact bundle.
        var evidenceDir = java.nio.file.Path.of("target", "r1-evidence");
        java.nio.file.Files.createDirectories(evidenceDir);
        for (String fileName : List.of("flutter-drift-evidence.json", "http-root-n2.json")) {
            var source = r5Signals.resolve(fileName);
            assertThat(java.nio.file.Files.exists(source))
                    .as("required R1 evidence must be present: %s", fileName).isTrue();
            java.nio.file.Files.copy(source, evidenceDir.resolve(fileName),
                    java.nio.file.StandardCopyOption.REPLACE_EXISTING);
        }
    }

    private record PublicationHttpFixture(UUID revisionId, UUID assetId, UUID candidateId,
            UUID collectionId, UUID memberId, List<PublicationExactContentRef> refs) {}

}
