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
@Table(name = "content_shadowing_revision", schema = "app")
@PrimaryKeyJoinColumn(name = "revision_id")
@DiscriminatorValue("shadowing")
public final class ShadowingContentRevisionEntity extends ContentRevisionEntity {

    @Column(name = "transcript", nullable = false, columnDefinition = "text")
    private String transcript;

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(
            name = "content_shadowing_segment",
            schema = "app",
            joinColumns = @JoinColumn(name = "revision_id"))
    @OrderColumn(name = "position")
    private List<ShadowingSegmentEmbeddable> segments = new ArrayList<>();

    protected ShadowingContentRevisionEntity() {
    }

    public ShadowingContentRevisionEntity(
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
            String transcript,
            List<ShadowingSegmentEmbeddable> segments) {
        super(contentCode, revisionNumber, checksum, title, subtitle, description,
                categoryCode, levelCode, minutes, skillCodes, availability);
        replaceBodyInternal(transcript, segments);
    }

    public void replaceDraftBody(String transcript, List<ShadowingSegmentEmbeddable> segments, Sha256Digest checksum) {
        ensureDraft();
        replaceBodyInternal(transcript, segments);
        replaceDraftChecksum(checksum);
    }

    private void replaceBodyInternal(String transcript, List<ShadowingSegmentEmbeddable> values) {
        var validatedSegments = ContentEntityRules.nonEmptyList(values, "segments");
        this.transcript = ContentEntityRules.requiredBodyText(transcript, "transcript");
        this.segments.clear();
        this.segments.addAll(validatedSegments);
    }

    @Override
    public ContentType getContentType() {
        return ContentType.SHADOWING;
    }

    @Override
    protected void validateBodyForFreeze() {
        ContentEntityRules.requiredBodyText(transcript, "transcript");
        ContentEntityRules.nonEmptyList(segments, "segments");
    }

    public String getTranscript() {
        return transcript;
    }

    public List<ShadowingSegmentEmbeddable> getSegments() {
        return List.copyOf(segments);
    }
}
