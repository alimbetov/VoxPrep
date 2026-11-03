package io.github.alimbetov.voxprep.backend.content.persistence;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OrderColumn;
import jakarta.persistence.PrimaryKeyJoinColumn;
import jakarta.persistence.Table;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;

@Entity
@Table(name = "content_question_revision", schema = "app")
@PrimaryKeyJoinColumn(name = "revision_id")
@DiscriminatorValue("question")
public final class QuestionContentRevisionEntity extends ContentRevisionEntity {

    @Column(name = "question_text", nullable = false, columnDefinition = "text")
    private String questionText;

    @Column(name = "explanation", nullable = false, columnDefinition = "text")
    private String explanation;

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(
            name = "content_question_option",
            schema = "app",
            joinColumns = @JoinColumn(name = "revision_id"))
    @OrderColumn(name = "position")
    private List<QuestionOptionEmbeddable> options = new ArrayList<>();

    protected QuestionContentRevisionEntity() {
    }

    public QuestionContentRevisionEntity(
            BusinessCode contentCode,
            RevisionNumber revisionNumber,
            Sha256Digest checksum,
            String title,
            String subtitle,
            String description,
            CatalogueCode categoryCode,
            CatalogueCode levelCode,
            int minutes,
            List<CatalogueCode> skillCodes,
            AvailabilityStatus availability,
            String questionText,
            String explanation,
            List<QuestionOptionEmbeddable> options) {
        super(contentCode, revisionNumber, checksum, title, subtitle, description,
                categoryCode, levelCode, minutes, skillCodes, availability);
        replaceBodyInternal(questionText, explanation, options);
    }

    public void replaceDraftBody(
            String questionText,
            String explanation,
            List<QuestionOptionEmbeddable> options,
            Sha256Digest checksum) {
        ensureDraft();
        replaceBodyInternal(questionText, explanation, options);
        replaceDraftChecksum(checksum);
    }

    private void replaceBodyInternal(
            String questionText,
            String explanation,
            List<QuestionOptionEmbeddable> options) {
        var validated = ContentEntityRules.nonEmptyList(options, "options");
        if (validated.size() < 2) {
            throw new IllegalArgumentException("options must contain at least two values");
        }
        var keys = validated.stream().map(QuestionOptionEmbeddable::getKey).toList();
        if (new HashSet<>(keys).size() != keys.size()) {
            throw new IllegalArgumentException("option keys must be unique");
        }
        if (validated.stream().noneMatch(QuestionOptionEmbeddable::isCorrect)) {
            throw new IllegalArgumentException("at least one question option must be correct");
        }
        this.questionText = ContentEntityRules.requiredBodyText(questionText, "questionText");
        this.explanation = ContentEntityRules.requiredBodyText(explanation, "explanation");
        this.options.clear();
        this.options.addAll(validated);
    }

    @Override
    public ContentType getContentType() {
        return ContentType.QUESTION;
    }

    @Override
    protected void validateBodyForFreeze() {
        replaceBodyValidation(questionText, explanation, options);
    }

    private static void replaceBodyValidation(
            String questionText,
            String explanation,
            List<QuestionOptionEmbeddable> options) {
        ContentEntityRules.requiredBodyText(questionText, "questionText");
        ContentEntityRules.requiredBodyText(explanation, "explanation");
        var validated = ContentEntityRules.nonEmptyList(options, "options");
        if (validated.size() < 2) {
            throw new IllegalArgumentException("options must contain at least two values");
        }
        if (new HashSet<>(validated.stream().map(QuestionOptionEmbeddable::getKey).toList()).size()
                != validated.size()) {
            throw new IllegalArgumentException("option keys must be unique");
        }
        if (validated.stream().noneMatch(QuestionOptionEmbeddable::isCorrect)) {
            throw new IllegalArgumentException("at least one question option must be correct");
        }
    }

    public String getQuestionText() {
        return questionText;
    }

    public String getExplanation() {
        return explanation;
    }

    public List<QuestionOptionEmbeddable> getOptions() {
        return List.copyOf(options);
    }
}
