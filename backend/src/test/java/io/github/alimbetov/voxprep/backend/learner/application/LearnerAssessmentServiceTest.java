package io.github.alimbetov.voxprep.backend.learner.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.PracticeTestContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.QuestionContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.QuestionOptionEmbeddable;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class LearnerAssessmentServiceTest {

    private static final String ROOT = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    private static final String TEST_SHA = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";
    private static final String QUESTION_SHA = "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc";

    private CurrentPublicationResolver currentPublicationResolver;
    private ContentRevisionRepository contentRevisionRepository;
    private LearnerAssessmentService service;

    @BeforeEach
    void setUp() {
        currentPublicationResolver = mock(CurrentPublicationResolver.class);
        contentRevisionRepository = mock(ContentRevisionRepository.class);
        service = new LearnerAssessmentService(currentPublicationResolver, contentRevisionRepository);
    }

    @Test
    void returnsPublishedPracticeTestWithoutCorrectAnswersOrExplanation() {
        UUID questionId = UUID.randomUUID();
        PublicationExactContentRef testRef = ref(ContentType.PRACTICE_TEST, "test-1", 2, TEST_SHA);
        PublicationExactContentRef questionRef = ref(ContentType.QUESTION, "question-1", 4, QUESTION_SHA);
        PracticeTestContentRevisionEntity test = mock(PracticeTestContentRevisionEntity.class);
        QuestionContentRevisionEntity question = mock(QuestionContentRevisionEntity.class);

        when(currentPublicationResolver.resolve()).thenReturn(publication(testRef, questionRef));
        when(contentRevisionRepository.findExact(testRef.identity())).thenReturn(Optional.of(test));
        when(test.getIdentity()).thenReturn(testRef.identity());
        when(test.getChecksum()).thenReturn(testRef.checksum());
        when(test.getContentCode()).thenReturn(new BusinessCode("test-1"));
        when(test.getRevisionNumber()).thenReturn(new RevisionNumber(2));
        when(test.getTitle()).thenReturn("Practice test");
        when(test.getSubtitle()).thenReturn("Subtitle");
        when(test.getDescription()).thenReturn("Description");
        when(test.getInstructions()).thenReturn("Choose the best answer");
        when(test.getPassingScorePercent()).thenReturn(80);
        when(test.getQuestionRevisionIds()).thenReturn(List.of(questionId));

        when(contentRevisionRepository.findById(questionId)).thenReturn(Optional.of(question));
        when(question.getIdentity()).thenReturn(questionRef.identity());
        when(question.getChecksum()).thenReturn(questionRef.checksum());
        when(question.getContentCode()).thenReturn(new BusinessCode("question-1"));
        when(question.getRevisionNumber()).thenReturn(new RevisionNumber(4));
        when(question.getQuestionText()).thenReturn("What is the answer?");
        when(question.getOptions()).thenReturn(List.of(
                new QuestionOptionEmbeddable("a", "First", false),
                new QuestionOptionEmbeddable("b", "Second", true)));

        LearnerAssessmentSnapshot result = service.getPracticeTest("test-1");

        assertThat(result.contentVersion()).isEqualTo(12L);
        assertThat(result.questions()).hasSize(1);
        assertThat(result.questions().get(0).questionText()).isEqualTo("What is the answer?");
        assertThat(result.questions().get(0).options())
                .containsExactly(
                        new LearnerAssessmentSnapshot.Option("a", "First"),
                        new LearnerAssessmentSnapshot.Option("b", "Second"));
    }

    @Test
    void failsClosedWhenPracticeTestQuestionIsNotFrozenInPublicationManifest() {
        UUID questionId = UUID.randomUUID();
        PublicationExactContentRef testRef = ref(ContentType.PRACTICE_TEST, "test-1", 2, TEST_SHA);
        PracticeTestContentRevisionEntity test = mock(PracticeTestContentRevisionEntity.class);
        QuestionContentRevisionEntity question = mock(QuestionContentRevisionEntity.class);
        ContentRevisionIdentity questionIdentity = new ContentRevisionIdentity(
                new BusinessCode("question-1"), ContentType.QUESTION, new RevisionNumber(4));

        when(currentPublicationResolver.resolve()).thenReturn(publication(testRef));
        when(contentRevisionRepository.findExact(testRef.identity())).thenReturn(Optional.of(test));
        when(test.getIdentity()).thenReturn(testRef.identity());
        when(test.getChecksum()).thenReturn(testRef.checksum());
        when(test.getQuestionRevisionIds()).thenReturn(List.of(questionId));
        when(contentRevisionRepository.findById(questionId)).thenReturn(Optional.of(question));
        when(question.getIdentity()).thenReturn(questionIdentity);

        assertThatThrownBy(() -> service.getPracticeTest("test-1"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("practice test question is absent from publication manifest");
    }

    private static CurrentPublicationSnapshot publication(PublicationExactContentRef... refs) {
        return new CurrentPublicationSnapshot(
                12L,
                ROOT,
                Instant.parse("2026-11-03T12:00:00Z"),
                List.of(refs));
    }

    private static PublicationExactContentRef ref(
            ContentType type,
            String code,
            int revision,
            String checksum) {
        return new PublicationExactContentRef(
                new ContentRevisionIdentity(
                        new BusinessCode(code),
                        type,
                        new RevisionNumber(revision)),
                new Sha256Digest(checksum));
    }
}
