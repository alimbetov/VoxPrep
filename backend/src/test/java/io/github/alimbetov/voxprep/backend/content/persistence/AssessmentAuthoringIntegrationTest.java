package io.github.alimbetov.voxprep.backend.content.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.application.ContentAuthoringService;
import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@ActiveProfiles("test")
@SpringBootTest
@Transactional
class AssessmentAuthoringIntegrationTest {

    @Autowired private ContentRevisionRepository repository;
    @Autowired private ContentAuthoringService authoringService;

    @Test
    void questionAndPracticeTestShareRevisionLifecycleAndPreserveExactOrderedMembership() {
        var firstQuestion = repository.saveAndFlush(question("assessment-question-a"));
        firstQuestion = (QuestionContentRevisionEntity) authoringService.markReadyForAudio(
                firstQuestion.getId(), firstQuestion.getVersion());
        firstQuestion = (QuestionContentRevisionEntity) authoringService.submitForReview(
                firstQuestion.getId(), firstQuestion.getVersion(), "admin", "assessment", "question ready");
        firstQuestion = (QuestionContentRevisionEntity) authoringService.approve(
                firstQuestion.getId(), firstQuestion.getVersion(), "admin", "assessment", "question approved");

        var secondQuestion = repository.saveAndFlush(question("assessment-question-b"));
        secondQuestion = (QuestionContentRevisionEntity) authoringService.markReadyForAudio(
                secondQuestion.getId(), secondQuestion.getVersion());
        secondQuestion = (QuestionContentRevisionEntity) authoringService.submitForReview(
                secondQuestion.getId(), secondQuestion.getVersion(), "admin", "assessment", "question ready");
        secondQuestion = (QuestionContentRevisionEntity) authoringService.approve(
                secondQuestion.getId(), secondQuestion.getVersion(), "admin", "assessment", "question approved");

        var test = repository.saveAndFlush(practiceTest(
                "assessment-practice-test",
                List.of(secondQuestion.getId(), firstQuestion.getId())));

        assertThat(test.getContentType()).isEqualTo(ContentType.PRACTICE_TEST);
        assertThat(test.getQuestionRevisionIds())
                .containsExactly(secondQuestion.getId(), firstQuestion.getId());

        test = (PracticeTestContentRevisionEntity) authoringService.markReadyForAudio(
                test.getId(), test.getVersion());
        test = (PracticeTestContentRevisionEntity) authoringService.submitForReview(
                test.getId(), test.getVersion(), "admin", "assessment", "test ready");
        test = (PracticeTestContentRevisionEntity) authoringService.approve(
                test.getId(), test.getVersion(), "admin", "assessment", "test approved");

        assertThat(test.getLifecycle()).isEqualTo(ContentLifecycleStatus.APPROVED);
        var frozen = test;
        assertThatThrownBy(() -> frozen.replaceDraftBody(
                "changed", 80, frozen.getQuestionRevisionIds(), new Sha256Digest("c".repeat(64))))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("DRAFT");
    }

    @Test
    void practiceTestRejectsNonQuestionRevisionReferenceAtPostgresqlBoundary() {
        var vocabulary = repository.saveAndFlush(new VocabularyContentRevisionEntity(
                new BusinessCode("assessment-not-question-" + UUID.randomUUID()),
                new RevisionNumber(1),
                new Sha256Digest("d".repeat(64)),
                "Vocabulary", "Vocabulary", "Vocabulary",
                new CatalogueCode("ASSESSMENT"), new CatalogueCode("B2"), 2,
                List.of(new CatalogueCode("READING")), AvailabilityStatus.ACTIVE,
                "term", "definition", "noun", List.of("example")));

        var invalid = practiceTest("assessment-invalid-test", List.of(vocabulary.getId()));
        assertThatThrownBy(() -> repository.saveAndFlush(invalid))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    private static QuestionContentRevisionEntity question(String code) {
        return new QuestionContentRevisionEntity(
                new BusinessCode(code + "-" + UUID.randomUUID()),
                new RevisionNumber(1),
                new Sha256Digest("a".repeat(64)),
                "Question", "Question", "Assessment question",
                new CatalogueCode("ASSESSMENT"), new CatalogueCode("B2"), 2,
                List.of(new CatalogueCode("READING")), AvailabilityStatus.ACTIVE,
                "Which answer is correct?",
                "Option B is correct.",
                List.of(
                        new QuestionOptionEmbeddable("A", "First answer", false),
                        new QuestionOptionEmbeddable("B", "Second answer", true)));
    }

    private static PracticeTestContentRevisionEntity practiceTest(String code, List<UUID> questionIds) {
        return new PracticeTestContentRevisionEntity(
                new BusinessCode(code + "-" + UUID.randomUUID()),
                new RevisionNumber(1),
                new Sha256Digest("b".repeat(64)),
                "Practice test", "Practice test", "Assessment practice test",
                new CatalogueCode("ASSESSMENT"), new CatalogueCode("B2"), 10,
                List.of(new CatalogueCode("READING")), AvailabilityStatus.ACTIVE,
                "Choose the correct answer for each question.",
                70,
                questionIds);
    }
}
