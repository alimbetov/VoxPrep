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
import java.util.UUID;

@Entity
@Table(name = "content_practice_test_revision", schema = "app")
@PrimaryKeyJoinColumn(name = "revision_id")
@DiscriminatorValue("practice_test")
public final class PracticeTestContentRevisionEntity extends ContentRevisionEntity {

    @Column(name = "instructions", nullable = false, columnDefinition = "text")
    private String instructions;

    @Column(name = "passing_score_percent", nullable = false)
    private int passingScorePercent;

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(
            name = "content_practice_test_question",
            schema = "app",
            joinColumns = @JoinColumn(name = "revision_id"))
    @OrderColumn(name = "position")
    @Column(name = "question_revision_id", nullable = false)
    private List<UUID> questionRevisionIds = new ArrayList<>();

    protected PracticeTestContentRevisionEntity() {
    }

    public PracticeTestContentRevisionEntity(
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
            String instructions,
            int passingScorePercent,
            List<UUID> questionRevisionIds) {
        super(contentCode, revisionNumber, checksum, title, subtitle, description,
                categoryCode, levelCode, minutes, skillCodes, availability);
        replaceBodyInternal(instructions, passingScorePercent, questionRevisionIds);
    }

    public void replaceDraftBody(
            String instructions,
            int passingScorePercent,
            List<UUID> questionRevisionIds,
            Sha256Digest checksum) {
        ensureDraft();
        replaceBodyInternal(instructions, passingScorePercent, questionRevisionIds);
        replaceDraftChecksum(checksum);
    }

    private void replaceBodyInternal(
            String instructions,
            int passingScorePercent,
            List<UUID> questionRevisionIds) {
        this.instructions = ContentEntityRules.requiredBodyText(instructions, "instructions");
        if (passingScorePercent < 1 || passingScorePercent > 100) {
            throw new IllegalArgumentException("passingScorePercent must be between 1 and 100");
        }
        var validated = ContentEntityRules.nonEmptyList(questionRevisionIds, "questionRevisionIds");
        if (new HashSet<>(validated).size() != validated.size()) {
            throw new IllegalArgumentException("questionRevisionIds must not contain duplicates");
        }
        this.passingScorePercent = passingScorePercent;
        this.questionRevisionIds.clear();
        this.questionRevisionIds.addAll(validated);
    }

    @Override
    public ContentType getContentType() {
        return ContentType.PRACTICE_TEST;
    }

    @Override
    protected void validateBodyForFreeze() {
        ContentEntityRules.requiredBodyText(instructions, "instructions");
        if (passingScorePercent < 1 || passingScorePercent > 100) {
            throw new IllegalArgumentException("passingScorePercent must be between 1 and 100");
        }
        var validated = ContentEntityRules.nonEmptyList(questionRevisionIds, "questionRevisionIds");
        if (new HashSet<>(validated).size() != validated.size()) {
            throw new IllegalArgumentException("questionRevisionIds must not contain duplicates");
        }
    }

    public String getInstructions() {
        return instructions;
    }

    public int getPassingScorePercent() {
        return passingScorePercent;
    }

    public List<UUID> getQuestionRevisionIds() {
        return List.copyOf(questionRevisionIds);
    }
}
