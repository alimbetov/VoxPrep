package io.github.alimbetov.voxprep.backend.content.persistence;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import jakarta.persistence.CollectionTable;
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
@Table(name = "content_topic_revision", schema = "app")
@PrimaryKeyJoinColumn(name = "revision_id")
@DiscriminatorValue("topic")
public final class TopicContentRevisionEntity extends ContentRevisionEntity {

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(
            name = "content_topic_section",
            schema = "app",
            joinColumns = @JoinColumn(name = "revision_id"))
    @OrderColumn(name = "position")
    private List<TopicSectionEmbeddable> sections = new ArrayList<>();

    protected TopicContentRevisionEntity() {
    }

    public TopicContentRevisionEntity(
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
            List<TopicSectionEmbeddable> sections) {
        super(contentCode, revisionNumber, checksum, title, subtitle, description,
                categoryCode, levelCode, minutes, skillCodes, availability);
        replaceBodyInternal(sections);
    }

    public void replaceDraftBody(List<TopicSectionEmbeddable> sections, Sha256Digest checksum) {
        ensureDraft();
        replaceBodyInternal(sections);
        replaceDraftChecksum(checksum);
    }

    private void replaceBodyInternal(List<TopicSectionEmbeddable> values) {
        var validated = ContentEntityRules.nonEmptyList(values, "sections");
        this.sections.clear();
        this.sections.addAll(validated);
    }

    @Override
    public ContentType getContentType() {
        return ContentType.TOPIC;
    }

    @Override
    protected void validateBodyForFreeze() {
        ContentEntityRules.nonEmptyList(sections, "sections");
    }

    public List<TopicSectionEmbeddable> getSections() {
        return List.copyOf(sections);
    }
}
