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
import java.util.List;

@Entity
@Table(name = "content_interview_revision", schema = "app")
@PrimaryKeyJoinColumn(name = "revision_id")
@DiscriminatorValue("interview")
public final class InterviewContentRevisionEntity extends ContentRevisionEntity {

    @Column(name = "prompt", nullable = false, columnDefinition = "text")
    private String prompt;

    @Column(name = "model_answer", nullable = false, columnDefinition = "text")
    private String modelAnswer;

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(
            name = "content_interview_key_point",
            schema = "app",
            joinColumns = @JoinColumn(name = "revision_id"))
    @OrderColumn(name = "position")
    @Column(name = "key_point", nullable = false, columnDefinition = "text")
    private List<String> keyPoints = new ArrayList<>();

    protected InterviewContentRevisionEntity() {
    }

    public InterviewContentRevisionEntity(
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
            String prompt,
            String modelAnswer,
            List<String> keyPoints) {
        super(contentCode, revisionNumber, checksum, title, subtitle, description,
                categoryCode, levelCode, minutes, skillCodes, availability);
        replaceBodyInternal(prompt, modelAnswer, keyPoints);
    }

    public void replaceDraftBody(String prompt, String modelAnswer, List<String> keyPoints, Sha256Digest checksum) {
        ensureDraft();
        replaceBodyInternal(prompt, modelAnswer, keyPoints);
        replaceDraftChecksum(checksum);
    }

    private void replaceBodyInternal(String prompt, String modelAnswer, List<String> keyPoints) {
        var validatedKeyPoints = ContentEntityRules.nonEmptyList(keyPoints, "keyPoints").stream()
                .map(value -> ContentEntityRules.requiredBodyText(value, "keyPoint"))
                .toList();
        this.prompt = ContentEntityRules.requiredBodyText(prompt, "prompt");
        this.modelAnswer = ContentEntityRules.requiredBodyText(modelAnswer, "modelAnswer");
        this.keyPoints.clear();
        this.keyPoints.addAll(validatedKeyPoints);
    }

    @Override
    public ContentType getContentType() {
        return ContentType.INTERVIEW;
    }

    @Override
    protected void validateBodyForFreeze() {
        ContentEntityRules.requiredBodyText(prompt, "prompt");
        ContentEntityRules.requiredBodyText(modelAnswer, "modelAnswer");
        ContentEntityRules.nonEmptyList(keyPoints, "keyPoints")
                .forEach(value -> ContentEntityRules.requiredBodyText(value, "keyPoint"));
    }

    public String getPrompt() {
        return prompt;
    }

    public String getModelAnswer() {
        return modelAnswer;
    }

    public List<String> getKeyPoints() {
        return List.copyOf(keyPoints);
    }
}
