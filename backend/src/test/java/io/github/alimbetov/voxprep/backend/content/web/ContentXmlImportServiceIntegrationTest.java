package io.github.alimbetov.voxprep.backend.content.web;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.TopicContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.PhraseContentRevisionEntity;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.core.io.ClassPathResource;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.support.TransactionTemplate;

@ActiveProfiles("test")
@SpringBootTest
class ContentXmlImportServiceIntegrationTest {
    @Autowired private ContentXmlImportService importer;
    @Autowired private ContentRevisionRepository revisions;
    @Autowired private TransactionTemplate transactions;
    @Autowired private io.github.alimbetov.voxprep.backend.content.application.ContentAuthoringService authoring;

    private byte[] exampleWithoutUnresolvedPracticeTest() throws Exception {
        String xml = new String(new ClassPathResource(
                "imports/voxprep-content-template-v1.xml").getContentAsByteArray(), StandardCharsets.UTF_8);
        return xml.replaceAll("(?s)\\s*<content code=\"PRACTICE_ARCH_01\".*?</content>", "")
                .getBytes(StandardCharsets.UTF_8);
    }

    @Test
    void importsSixTypedDraftsAtomicallyAndReplaysWithoutDuplicates() throws Exception {
        byte[] xml = exampleWithoutUnresolvedPracticeTest();
        long before = revisions.count();
        var imported = importer.importDrafts(xml);
        assertThat(imported.created()).isEqualTo(6);
        assertThat(imported.alreadyPresent()).isZero();
        assertThat(revisions.count()).isEqualTo(before + 6);
        var replay = importer.importDrafts(xml);
        assertThat(replay.created()).isZero();
        assertThat(replay.alreadyPresent()).isEqualTo(6);
        assertThat(revisions.count()).isEqualTo(before + 6);
        var draftId = revisions.findIdByExactIdentity("PHRASE_INTERVIEW_INTRO_01", "phrase", 1);
        assertThat(draftId).isPresent();
        assertThat(revisions.findById(draftId.orElseThrow()).orElseThrow().getLifecycle())
                .isEqualTo(ContentLifecycleStatus.DRAFT);
    }

    @Test
    void unresolvedPracticeTestQuestionRejectsAllWrites() throws Exception {
        byte[] xml = new ClassPathResource("imports/voxprep-content-template-v1.xml")
                .getContentAsByteArray();
        long before = revisions.count();
        assertThatThrownBy(() -> importer.importDrafts(xml))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Unresolved approved Question");
        assertThat(revisions.count()).isEqualTo(before);
    }

    private static String onlyEntry(String template, String code) {
        int start = template.indexOf("  <content code=\"" + code + "\"");
        int end = template.indexOf("</content>", start) + "</content>".length();
        if (start < 0 || end < "</content>".length()) throw new IllegalArgumentException("Missing fixture " + code);
        return "<voxprep schemaVersion=\"1\">\n" + template.substring(start, end) + "\n</voxprep>";
    }

    @Test
    void importedTopicPersistsPipesAndMultilineSectionExactly() throws Exception {
        String base = new String(new ClassPathResource("imports/voxprep-content-template-v1.xml")
                .getContentAsByteArray(), StandardCharsets.UTF_8);
        String code = "TOPIC_PIPE_" + UUID.randomUUID().toString().replace("-", "");
        String xml = onlyEntry(base, "TOPIC_REST_01").replace("TOPIC_REST_01", code)
                .replace("<heading>HTTP</heading>", "<heading>HTTP | REST</heading>")
                .replace("<text>Resources have stable URIs.</text>",
                        "<text>First | line\nSecond line</text>");
        var result = importer.importDrafts(xml.getBytes(StandardCharsets.UTF_8));
        assertThat(result.created()).isEqualTo(1);
        var id = revisions.findIdByExactIdentity(code, "topic", 1).orElseThrow();
        transactions.executeWithoutResult(status -> {
            var revision = (TopicContentRevisionEntity) revisions.findById(id).orElseThrow();
            assertThat(revision.getSections()).hasSize(1);
            assertThat(revision.getSections().getFirst().getHeading()).isEqualTo("HTTP | REST");
            assertThat(revision.getSections().getFirst().getText()).isEqualTo("First | line\nSecond line");
        });
    }

    @Test
    void importedPhraseKeepsOneMultilineExampleWithPipe() throws Exception {
        String base = new String(new ClassPathResource("imports/voxprep-content-template-v1.xml")
                .getContentAsByteArray(), StandardCharsets.UTF_8);
        String code = "PHRASE_LINES_" + UUID.randomUUID().toString().replace("-", "");
        String xml = onlyEntry(base, "PHRASE_INTERVIEW_INTRO_01")
                .replace("PHRASE_INTERVIEW_INTRO_01", code)
                .replace("<example>I specialize in designing scalable APIs.</example>",
                        "<example>First | line\nSecond line</example>");
        var result = importer.importDrafts(xml.getBytes(StandardCharsets.UTF_8));
        assertThat(result.created()).isEqualTo(1);
        var id = revisions.findIdByExactIdentity(code, "phrase", 1).orElseThrow();
        transactions.executeWithoutResult(status -> {
            var revision = (PhraseContentRevisionEntity) revisions.findById(id).orElseThrow();
            assertThat(revision.getExamples()).containsExactly("First | line\nSecond line");
        });
    }

    @Test
    void laterDomainFailureRollsBackPreviouslyInsertedDraft() throws Exception {
        String base = new String(new ClassPathResource("imports/voxprep-content-template-v1.xml")
                .getContentAsByteArray(), StandardCharsets.UTF_8);
        String firstCode = "ROLLBACK_P_" + UUID.randomUUID().toString().replace("-", "");
        String secondCode = "ROLLBACK_V_" + UUID.randomUUID().toString().replace("-", "");
        String phrase = onlyEntry(base, "PHRASE_INTERVIEW_INTRO_01")
                .replace("PHRASE_INTERVIEW_INTRO_01", firstCode)
                .replace("<voxprep schemaVersion=\"1\">", "").replace("</voxprep>", "");
        String vocab = onlyEntry(base, "VOCAB_RESILIENCE_01")
                .replace("VOCAB_RESILIENCE_01", secondCode)
                .replace("<voxprep schemaVersion=\"1\">", "").replace("</voxprep>", "")
                .replace("<partOfSpeech>noun</partOfSpeech>",
                        "<partOfSpeech>" + "x".repeat(200) + "</partOfSpeech>");
        String xml = "<voxprep schemaVersion=\"1\">" + phrase + vocab + "</voxprep>";
        long before = revisions.count();
        assertThatThrownBy(() -> importer.importDrafts(xml.getBytes(StandardCharsets.UTF_8)))
                .isInstanceOf(IllegalArgumentException.class);
        assertThat(revisions.findIdByExactIdentity(firstCode, "phrase", 1)).isEmpty();
        assertThat(revisions.findIdByExactIdentity(secondCode, "vocabulary", 1)).isEmpty();
        assertThat(revisions.count()).isEqualTo(before);
    }

    @Test
    void simultaneousIdenticalImportsCreateExactlyOneDraft() throws Exception {
        String base = new String(new ClassPathResource("imports/voxprep-content-template-v1.xml")
                .getContentAsByteArray(), StandardCharsets.UTF_8);
        String code = "CONCURRENT_P_" + UUID.randomUUID().toString().replace("-", "");
        byte[] xml = onlyEntry(base, "PHRASE_INTERVIEW_INTRO_01")
                .replace("PHRASE_INTERVIEW_INTRO_01", code).getBytes(StandardCharsets.UTF_8);
        var start = new CountDownLatch(1);
        try (var executor = Executors.newFixedThreadPool(2)) {
            var first = executor.submit(() -> {
                start.await();
                return importer.importDrafts(xml);
            });
            var second = executor.submit(() -> {
                start.await();
                return importer.importDrafts(xml);
            });
            start.countDown();
            var left = first.get(30, TimeUnit.SECONDS);
            var right = second.get(30, TimeUnit.SECONDS);
            assertThat(left.created() + right.created()).isEqualTo(1);
            assertThat(left.alreadyPresent() + right.alreadyPresent()).isEqualTo(1);
            assertThat(revisions.findIdByExactIdentity(code, "phrase", 1)).isPresent();
        }
    }

    @Test
    void changedPayloadWithSameContentIdentityIsRejectedWithoutModification() throws Exception {
        String base = new String(new ClassPathResource("imports/voxprep-content-template-v1.xml")
                .getContentAsByteArray(), StandardCharsets.UTF_8);
        String code = "CONFLICT_" + UUID.randomUUID().toString().replace("-", "");
        String xml = onlyEntry(base, "PHRASE_INTERVIEW_INTRO_01")
                .replace("PHRASE_INTERVIEW_INTRO_01", code);
        byte[] original = xml.getBytes(StandardCharsets.UTF_8);
        importer.importDrafts(original);
        var id = revisions.findIdByExactIdentity(code, "phrase", 1).orElseThrow();
        var originalDigest = revisions.findById(id).orElseThrow().getChecksum();

        String changed = xml.replace("Introduce your technical background.",
                "Introduce your different background.");
        assertThatThrownBy(() -> importer.importDrafts(changed.getBytes(StandardCharsets.UTF_8)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Row conflict");
        assertThat(revisions.findById(id).orElseThrow().getChecksum()).isEqualTo(originalDigest);
    }

    @Test
    void immutableRevisionCannotBeReimportedEvenWithIdenticalPayload() throws Exception {
        String base = new String(new ClassPathResource("imports/voxprep-content-template-v1.xml")
                .getContentAsByteArray(), StandardCharsets.UTF_8);
        String code = "IMMUTABLE_" + UUID.randomUUID().toString().replace("-", "");
        byte[] xml = onlyEntry(base, "PHRASE_INTERVIEW_INTRO_01")
                .replace("PHRASE_INTERVIEW_INTRO_01", code).getBytes(StandardCharsets.UTF_8);
        importer.importDrafts(xml);
        var id = revisions.findIdByExactIdentity(code, "phrase", 1).orElseThrow();
        authoring.markReadyForAudio(id);
        assertThatThrownBy(() -> importer.preflight(xml))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("immutable");
        assertThatThrownBy(() -> importer.importDrafts(xml))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("immutable");
        assertThat(revisions.findById(id).orElseThrow().getLifecycle())
                .isEqualTo(ContentLifecycleStatus.READY_FOR_AUDIO);
    }

    @Test
    void practiceTestReferencesRealApprovedQuestionAndCreatesOnlyDraft() throws Exception {
        String base = new String(new ClassPathResource("imports/voxprep-content-template-v1.xml")
                .getContentAsByteArray(), StandardCharsets.UTF_8);
        String questionCode = "APPROVED_Q_" + UUID.randomUUID().toString().replace("-", "");
        byte[] question = onlyEntry(base, "QUESTION_COUPLING_01")
                .replace("QUESTION_COUPLING_01", questionCode).getBytes(StandardCharsets.UTF_8);
        importer.importDrafts(question);
        var questionId = revisions.findIdByExactIdentity(questionCode, "question", 1).orElseThrow();
        authoring.markReadyForAudio(questionId);
        authoring.submitForReview(questionId);
        authoring.approve(questionId, java.time.Instant.now());

        String testCode = "TEST_REF_" + UUID.randomUUID().toString().replace("-", "");
        String xml = onlyEntry(base, "PRACTICE_ARCH_01")
                .replace("PRACTICE_ARCH_01", testCode)
                .replace("00000000-0000-0000-0000-000000000001", questionId.toString());
        var plan = importer.preflight(xml.getBytes(StandardCharsets.UTF_8));
        assertThat(plan.toCreate()).isEqualTo(1);
        importer.importDrafts(xml.getBytes(StandardCharsets.UTF_8));
        var testId = revisions.findIdByExactIdentity(testCode, "practice_test", 1).orElseThrow();
        assertThat(revisions.findById(testId).orElseThrow().getLifecycle())
                .isEqualTo(ContentLifecycleStatus.DRAFT);
        transactions.executeWithoutResult(status -> {
            var revision = (io.github.alimbetov.voxprep.backend.content.persistence.PracticeTestContentRevisionEntity)
                    revisions.findById(testId).orElseThrow();
            assertThat(revision.getQuestionRevisionIds()).containsExactly(questionId);
        });
    }

    @Test
    void formattingOnlyChangeReplaysExistingDraftWithoutNewRevision() throws Exception {
        String base = new String(new ClassPathResource("imports/voxprep-content-template-v1.xml")
                .getContentAsByteArray(), StandardCharsets.UTF_8);
        String code = "FORMAT_REPLAY_" + UUID.randomUUID().toString().replace("-", "");
        String xml = onlyEntry(base, "PHRASE_INTERVIEW_INTRO_01")
                .replace("PHRASE_INTERVIEW_INTRO_01", code);
        var first = importer.importDrafts(xml.getBytes(StandardCharsets.UTF_8));
        assertThat(first.created()).isEqualTo(1);

        String formatted = xml.replace("<body>", "<body>\n    ")
                .replace("</body>", "\n  </body>");
        var replay = importer.importDrafts(formatted.getBytes(StandardCharsets.UTF_8));
        assertThat(replay.created()).isZero();
        assertThat(replay.alreadyPresent()).isEqualTo(1);
        assertThat(revisions.findIdByExactIdentity(code, "phrase", 1)).isPresent();
    }

    @Test
    void oneHundredDraftBatchCommitsAndIdenticalReplaySkipsAll() {
        String prefix = "BATCH_" + UUID.randomUUID().toString().replace("-", "");
        var xml = new StringBuilder("<voxprep schemaVersion=\"1\">");
        for (int index = 0; index < 100; index++) {
            xml.append("""
                  <content code="%s_%03d" type="phrase">
                    <title>Interview practice</title><subtitle>English</subtitle>
                    <description>Batch test</description><categoryCode>INTERVIEW</categoryCode>
                    <levelCode>B2</levelCode><minutes>2</minutes><availability>ACTIVE</availability>
                    <skill>SPEAKING</skill>
                    <body><phrase>I work with Java.</phrase><usage>Interview answer.</usage></body>
                  </content>
                    """.formatted(prefix, index));
        }
        xml.append("</voxprep>");
        byte[] file = xml.toString().getBytes(StandardCharsets.UTF_8);
        long before = revisions.count();
        var plan = importer.preflight(file);
        assertThat(plan.toCreate()).isEqualTo(100);
        assertThat(importer.importDrafts(file).created()).isEqualTo(100);
        assertThat(revisions.count()).isEqualTo(before + 100);
        var replay = importer.importDrafts(file);
        assertThat(replay.created()).isZero();
        assertThat(replay.alreadyPresent()).isEqualTo(100);
        assertThat(revisions.count()).isEqualTo(before + 100);
    }

    @Test
    void invalidXmlCannotCausePartialWrites() throws Exception {
        byte[] xml = exampleWithoutUnresolvedPracticeTest();
        String invalid = new String(xml, StandardCharsets.UTF_8)
                .replace("<minutes>2</minutes>", "<minutes>-5</minutes>");
        long before = revisions.count();
        assertThatThrownBy(() -> importer.importDrafts(invalid.getBytes(StandardCharsets.UTF_8)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("XML validation failed");
        assertThat(revisions.count()).isEqualTo(before);
    }
}
