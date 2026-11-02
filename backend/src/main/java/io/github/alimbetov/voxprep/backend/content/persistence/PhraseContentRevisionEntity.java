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
@Table(name = "content_phrase_revision", schema = "app")
@PrimaryKeyJoinColumn(name = "revision_id")
@DiscriminatorValue("phrase")
public final class PhraseContentRevisionEntity extends ContentRevisionEntity {

    @Column(name = "phrase", nullable = false, columnDefinition = "text")
    private String phrase;

    @Column(name = "usage", nullable = false, columnDefinition = "text")
    private String usage;

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(
            name = "content_phrase_example",
            schema = "app",
            joinColumns = @JoinColumn(name = "revision_id"))
    @OrderColumn(name = "position")
    @Column(name = "example_text", nullable = false, columnDefinition = "text")
    private List<String> examples = new ArrayList<>();

    protected PhraseContentRevisionEntity() {
    }

    public PhraseContentRevisionEntity(
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
            String phrase,
            String usage,
            List<String> examples) {
        super(contentCode, revisionNumber, checksum, title, subtitle, description,
                categoryCode, levelCode, minutes, skillCodes, availability);
        replaceBodyInternal(phrase, usage, examples);
    }

    public void replaceDraftBody(String phrase, String usage, List<String> examples, Sha256Digest checksum) {
        ensureDraft();
        replaceBodyInternal(phrase, usage, examples);
        replaceDraftChecksum(checksum);
    }

    private void replaceBodyInternal(String phrase, String usage, List<String> examples) {
        var validatedExamples = ContentEntityRules.nonEmptyList(examples, "examples").stream()
                .map(value -> ContentEntityRules.requiredBodyText(value, "example"))
                .toList();
        this.phrase = ContentEntityRules.requiredBodyText(phrase, "phrase");
        this.usage = ContentEntityRules.requiredBodyText(usage, "usage");
        this.examples.clear();
        this.examples.addAll(validatedExamples);
    }

    @Override
    public ContentType getContentType() {
        return ContentType.PHRASE;
    }

    @Override
    protected void validateBodyForFreeze() {
        ContentEntityRules.requiredBodyText(phrase, "phrase");
        ContentEntityRules.requiredBodyText(usage, "usage");
        ContentEntityRules.nonEmptyList(examples, "examples")
                .forEach(value -> ContentEntityRules.requiredBodyText(value, "example"));
    }

    public String getPhrase() {
        return phrase;
    }

    public String getUsage() {
        return usage;
    }

    public List<String> getExamples() {
        return List.copyOf(examples);
    }
}
