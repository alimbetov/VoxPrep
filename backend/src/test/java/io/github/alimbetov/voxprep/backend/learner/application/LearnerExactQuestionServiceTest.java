package io.github.alimbetov.voxprep.backend.learner.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
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
import org.junit.jupiter.api.Test;

class LearnerExactQuestionServiceTest {
    private static final UUID ID = UUID.fromString("11111111-1111-4111-8111-111111111111");
    private final CurrentPublicationResolver publication = mock(CurrentPublicationResolver.class);
    private final ContentRevisionRepository revisions = mock(ContentRevisionRepository.class);
    private final LearnerContentAccessPolicy access = mock(LearnerContentAccessPolicy.class);
    private final LearnerExactQuestionService service =
            new LearnerExactQuestionService(publication, revisions, access);

    @Test
    void publishedQuestionUsesExactFlutterSingleChoicePayload() {
        publishedQuestion(
                List.of(new QuestionOptionEmbeddable("a", "First", false),
                        new QuestionOptionEmbeddable("b", "Second", true)),
                List.of(new CatalogueCode("GRAMMAR")), true);

        var result = service.get("Q_01", 2);

        assertThat(result.questionCode()).isEqualTo("Q_01");
        assertThat(result.revision()).isEqualTo(2);
        assertThat(result.checksum()).isEqualTo("c".repeat(64));
        assertThat(result.body().kind()).isEqualTo("singleChoice");
        assertThat(result.body().options()).containsExactly("First", "Second");
        assertThat(result.body().correctOptionIndex()).isEqualTo(1);
        assertThat(result.body().skillCode()).isEqualTo("GRAMMAR");
        verify(access).requireAccessible("practice_test", "TEST_01");
    }

    @Test
    void unreferencedQuestionIsNotPublicByGuessingItsCode() {
        publishedQuestion(
                List.of(new QuestionOptionEmbeddable("a", "First", false),
                        new QuestionOptionEmbeddable("b", "Second", true)),
                List.of(new CatalogueCode("GRAMMAR")), false);
        assertThatThrownBy(() -> service.get("Q_01", 2))
                .isInstanceOf(LearnerContentNotFoundException.class);
        verifyNoInteractions(access);
    }

    @Test
    void paidParentBlocksDirectQuestionAndNoAnswersEscape() {
        publishedQuestion(
                List.of(new QuestionOptionEmbeddable("a", "First", false),
                        new QuestionOptionEmbeddable("b", "Second", true)),
                List.of(new CatalogueCode("GRAMMAR")), true);
        doThrow(new LearnerPremiumAccessDeniedException())
                .when(access).requireAccessible("practice_test", "TEST_01");
        assertThatThrownBy(() -> service.get("Q_01", 2))
                .isInstanceOf(LearnerPremiumAccessDeniedException.class);
    }

    @Test
    void ambiguousMultipleCorrectAnswersFailClosedRatherThanFabricatingSingleChoice() {
        publishedQuestion(
                List.of(new QuestionOptionEmbeddable("a", "First", true),
                        new QuestionOptionEmbeddable("b", "Second", true)),
                List.of(new CatalogueCode("GRAMMAR")), true);
        assertThatThrownBy(() -> service.get("Q_01", 2))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("singleChoice");
    }

    @Test
    void missingSkillFailsClosedAndWrongExactRevisionIsNotServed() {
        publishedQuestion(
                List.of(new QuestionOptionEmbeddable("a", "First", true),
                        new QuestionOptionEmbeddable("b", "Second", false)),
                List.of(), true);
        assertThatThrownBy(() -> service.get("Q_01", 2))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("exactly one");
        assertThatThrownBy(() -> service.get("Q_01", 3))
                .isInstanceOf(LearnerContentNotFoundException.class);
    }

    private void publishedQuestion(
            List<QuestionOptionEmbeddable> options,
            List<CatalogueCode> skills, boolean belongsToTest) {
        var qRef = ref(ContentType.QUESTION, "Q_01", 2, "c".repeat(64));
        var tRef = ref(ContentType.PRACTICE_TEST, "TEST_01", 1, "b".repeat(64));
        when(publication.resolve()).thenReturn(new CurrentPublicationSnapshot(
                1, "a".repeat(64), Instant.parse("2026-11-03T00:00:00Z"), List.of(qRef, tRef)));

        var question = mock(QuestionContentRevisionEntity.class);
        when(revisions.findExact(qRef.identity())).thenReturn(Optional.of(question));
        when(question.getId()).thenReturn(ID);
        when(question.getIdentity()).thenReturn(qRef.identity());
        when(question.getChecksum()).thenReturn(qRef.checksum());
        when(question.getOptions()).thenReturn(options);
        when(question.getSkillCodes()).thenReturn(skills);
        when(question.getQuestionText()).thenReturn("Which answer?");
        when(question.getExplanation()).thenReturn("Reason.");

        var test = mock(PracticeTestContentRevisionEntity.class);
        when(revisions.findExact(tRef.identity())).thenReturn(Optional.of(test));
        when(test.getIdentity()).thenReturn(tRef.identity());
        when(test.getChecksum()).thenReturn(tRef.checksum());
        when(test.getQuestionRevisionIds()).thenReturn(belongsToTest ? List.of(ID) : List.of());
    }

    private static PublicationExactContentRef ref(
            ContentType type, String code, int revision, String checksum) {
        return new PublicationExactContentRef(
                new ContentRevisionIdentity(
                        new BusinessCode(code), type, new RevisionNumber(revision)),
                new Sha256Digest(checksum));
    }
}
