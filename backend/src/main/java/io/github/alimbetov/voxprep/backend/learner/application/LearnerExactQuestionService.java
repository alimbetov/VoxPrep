package io.github.alimbetov.voxprep.backend.learner.application;

import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.PracticeTestContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.QuestionContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.QuestionOptionEmbeddable;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import java.util.List;
import java.util.Objects;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Exact Flutter question endpoint. A published question can be read only if
 * at least one published practice test references its exact immutable revision.
 * All such parent tests must be entitled: a FREE alias never bypasses FULL.
 */
@Service
public class LearnerExactQuestionService {

    private final CurrentPublicationResolver publication;
    private final ContentRevisionRepository revisions;
    private final LearnerContentAccessPolicy access;

    public LearnerExactQuestionService(
            CurrentPublicationResolver publication,
            ContentRevisionRepository revisions,
            LearnerContentAccessPolicy access) {
        this.publication = Objects.requireNonNull(publication);
        this.revisions = Objects.requireNonNull(revisions);
        this.access = Objects.requireNonNull(access);
    }

    @Transactional(readOnly = true)
    public QuestionPayload get(String questionCode, int revision) {
        if (revision < 1) {
            throw new IllegalArgumentException("revision must be positive");
        }
        var refs = publication.resolve().refs();
        var ref = refs.stream()
                .filter(item -> item.identity().contentType() == ContentType.QUESTION)
                .filter(item -> item.identity().contentCode().value().equals(questionCode))
                .filter(item -> item.identity().revisionNumber().value() == revision)
                .findFirst()
                .orElseThrow(() -> new LearnerContentNotFoundException("question", questionCode));

        var raw = revisions.findExact(ref.identity())
                .orElseThrow(() -> new IllegalStateException("published question revision is missing"));
        if (!(raw instanceof QuestionContentRevisionEntity question)
                || !raw.getChecksum().equals(ref.checksum())
                || !raw.getIdentity().equals(ref.identity())) {
            throw new IllegalStateException("question revision differs from CURRENT publication");
        }

        int parentCount = 0;
        for (PublicationExactContentRef candidate : refs) {
            if (candidate.identity().contentType() != ContentType.PRACTICE_TEST) {
                continue;
            }
            var rawTest = revisions.findExact(candidate.identity())
                    .orElseThrow(() -> new IllegalStateException("published practice test revision is missing"));
            if (!(rawTest instanceof PracticeTestContentRevisionEntity test)
                    || !rawTest.getChecksum().equals(candidate.checksum())
                    || !rawTest.getIdentity().equals(candidate.identity())) {
                throw new IllegalStateException("practice test differs from CURRENT publication");
            }
            if (test.getQuestionRevisionIds().contains(question.getId())) {
                // Verify every parent; one inaccessible FULL test blocks shared questions.
                access.requireAccessible("practice_test", candidate.identity().contentCode().value());
                parentCount++;
            }
        }
        if (parentCount == 0) {
            throw new LearnerContentNotFoundException("question", questionCode);
        }

        var skills = question.getSkillCodes();
        if (skills.size() != 1) {
            throw new IllegalStateException("singleChoice questions require exactly one published skill");
        }
        List<QuestionOptionEmbeddable> options = question.getOptions();
        long correctCount = options.stream().filter(QuestionOptionEmbeddable::isCorrect).count();
        if (options.size() < 2 || correctCount != 1) {
            // Existing authoring allows multiple correct options. Flutter does not.
            throw new IllegalStateException("published question does not satisfy singleChoice contract");
        }
        int correctIndex = -1;
        for (int i = 0; i < options.size(); i++) {
            if (options.get(i).isCorrect()) {
                correctIndex = i;
            }
        }
        return new QuestionPayload(questionCode, revision, ref.checksum().value(),
                new SingleChoiceBody("singleChoice",
                        question.getQuestionText(),
                        options.stream().map(QuestionOptionEmbeddable::getText).toList(),
                        correctIndex,
                        skills.get(0).value(),
                        question.getExplanation()));
    }

    public record QuestionPayload(
            String questionCode, int revision, String checksum, SingleChoiceBody body) {
    }

    public record SingleChoiceBody(
            String kind,
            String prompt,
            List<String> options,
            int correctOptionIndex,
            String skillCode,
            String explanation) {
        public SingleChoiceBody {
            options = List.copyOf(options);
        }
    }
}
