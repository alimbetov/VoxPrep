package io.github.alimbetov.voxprep.backend.learner.application;

import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.PracticeTestContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.QuestionContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import java.util.List;
import java.util.Objects;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class LearnerAssessmentService {

    private final CurrentPublicationResolver currentPublicationResolver;
    private final ContentRevisionRepository contentRevisionRepository;

    public LearnerAssessmentService(
            CurrentPublicationResolver currentPublicationResolver,
            ContentRevisionRepository contentRevisionRepository) {
        this.currentPublicationResolver = Objects.requireNonNull(currentPublicationResolver, "currentPublicationResolver");
        this.contentRevisionRepository = Objects.requireNonNull(contentRevisionRepository, "contentRevisionRepository");
    }

    @Transactional(readOnly = true)
    public LearnerAssessmentSnapshot getPracticeTest(String contentCode) {
        CurrentPublicationSnapshot publication = currentPublicationResolver.resolve();
        PublicationExactContentRef testRef = publication.refs().stream()
                .filter(ref -> ref.identity().contentType() == ContentType.PRACTICE_TEST)
                .filter(ref -> ref.identity().contentCode().value().equals(contentCode))
                .findFirst()
                .orElseThrow(() -> new LearnerContentNotFoundException("practice_test", contentCode));

        ContentRevisionEntity rawTest = contentRevisionRepository.findExact(testRef.identity())
                .orElseThrow(() -> new IllegalStateException("published practice test revision is missing"));
        if (!(rawTest instanceof PracticeTestContentRevisionEntity test)) {
            throw new IllegalStateException("published practice test has unexpected entity type");
        }
        requireChecksum(test, testRef, "practice test");

        List<LearnerAssessmentSnapshot.Question> questions = test.getQuestionRevisionIds().stream()
                .map(questionId -> loadQuestion(publication, questionId))
                .toList();

        return new LearnerAssessmentSnapshot(
                publication.contentVersion(),
                publication.rootSha256(),
                test.getContentCode().value(),
                test.getRevisionNumber().value(),
                test.getChecksum().value(),
                test.getTitle(),
                test.getSubtitle(),
                test.getDescription(),
                test.getInstructions(),
                test.getPassingScorePercent(),
                questions);
    }

    private LearnerAssessmentSnapshot.Question loadQuestion(
            CurrentPublicationSnapshot publication,
            java.util.UUID questionId) {
        ContentRevisionEntity rawQuestion = contentRevisionRepository.findById(questionId)
                .orElseThrow(() -> new IllegalStateException("published assessment question revision is missing"));
        if (!(rawQuestion instanceof QuestionContentRevisionEntity question)) {
            throw new IllegalStateException("practice test references a non-question revision");
        }

        PublicationExactContentRef questionRef = publication.refs().stream()
                .filter(ref -> ref.identity().equals(question.getIdentity()))
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("practice test question is absent from publication manifest"));
        requireChecksum(question, questionRef, "assessment question");

        return new LearnerAssessmentSnapshot.Question(
                question.getContentCode().value(),
                question.getRevisionNumber().value(),
                question.getChecksum().value(),
                question.getQuestionText(),
                question.getOptions().stream()
                        .map(option -> new LearnerAssessmentSnapshot.Option(option.getKey(), option.getText()))
                        .toList());
    }

    private static void requireChecksum(
            ContentRevisionEntity revision,
            PublicationExactContentRef ref,
            String subject) {
        if (!revision.getIdentity().equals(ref.identity())) {
            throw new IllegalStateException("published " + subject + " identity differs from publication manifest");
        }
        if (!revision.getChecksum().equals(ref.checksum())) {
            throw new IllegalStateException("published " + subject + " checksum differs from publication manifest");
        }
    }
}
