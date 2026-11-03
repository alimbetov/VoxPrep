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
@Table(name = "content_vocabulary_revision", schema = "app")
@PrimaryKeyJoinColumn(name = "revision_id")
@DiscriminatorValue("vocabulary")
public final class VocabularyContentRevisionEntity extends ContentRevisionEntity {

    @Column(name = "term", nullable = false, columnDefinition = "text")
    private String term;

    @Column(name = "definition", nullable = false, columnDefinition = "text")
    private String definition;

    @Column(name = "part_of_speech", length = ContentEntityRules.PART_OF_SPEECH_MAX_LENGTH)
    private String partOfSpeech;

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(
            name = "content_vocabulary_example",
            schema = "app",
            joinColumns = @JoinColumn(name = "revision_id"))
    @OrderColumn(name = "position")
    @Column(name = "example_text", nullable = false, columnDefinition = "text")
    private List<String> examples = new ArrayList<>();

    protected VocabularyContentRevisionEntity() {
    }

    public VocabularyContentRevisionEntity(
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
            String term,
            String definition,
            String partOfSpeech,
            List<String> examples) {
        super(contentCode, revisionNumber, checksum, title, subtitle, description,
                categoryCode, levelCode, minutes, skillCodes, availability);
        replaceBodyInternal(term, definition, partOfSpeech, examples);
    }

    public void replaceDraftBody(
            String term,
            String definition,
            String partOfSpeech,
            List<String> examples,
            Sha256Digest checksum) {
        ensureDraft();
        replaceBodyInternal(term, definition, partOfSpeech, examples);
        replaceDraftChecksum(checksum);
    }

    private void replaceBodyInternal(String term, String definition, String partOfSpeech, List<String> examples) {
        var validatedExamples = ContentEntityRules.nonEmptyList(examples, "examples").stream()
                .map(value -> ContentEntityRules.requiredBodyText(value, "example"))
                .toList();
        this.term = ContentEntityRules.requiredBodyText(term, "term");
        this.definition = ContentEntityRules.requiredBodyText(definition, "definition");
        this.partOfSpeech = ContentEntityRules.optionalText(
                partOfSpeech, "partOfSpeech", ContentEntityRules.PART_OF_SPEECH_MAX_LENGTH);
        this.examples.clear();
        this.examples.addAll(validatedExamples);
    }

    @Override
    public ContentType getContentType() {
        return ContentType.VOCABULARY;
    }

    @Override
    protected void validateBodyForFreeze() {
        ContentEntityRules.requiredBodyText(term, "term");
        ContentEntityRules.requiredBodyText(definition, "definition");
        ContentEntityRules.optionalText(partOfSpeech, "partOfSpeech", ContentEntityRules.PART_OF_SPEECH_MAX_LENGTH);
        ContentEntityRules.nonEmptyList(examples, "examples")
                .forEach(value -> ContentEntityRules.requiredBodyText(value, "example"));
    }

    public String getTerm() {
        return term;
    }

    public String getDefinition() {
        return definition;
    }

    public String getPartOfSpeech() {
        return partOfSpeech;
    }

    public List<String> getExamples() {
        return List.copyOf(examples);
    }
}
