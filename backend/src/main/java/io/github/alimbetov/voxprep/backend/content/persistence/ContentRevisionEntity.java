package io.github.alimbetov.voxprep.backend.content.persistence;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.infrastructure.persistence.AbstractJpaEntity;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.DiscriminatorColumn;
import jakarta.persistence.DiscriminatorType;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Index;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OrderColumn;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

@Entity
@Table(
        name = "content_revision",
        schema = "app",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_content_revision__identity",
                columnNames = {"content_code", "content_type", "revision_number"}),
        indexes = @Index(
                name = "ix_content_revision__lifecycle_availability",
                columnList = "lifecycle, availability"))
@Inheritance(strategy = InheritanceType.JOINED)
@DiscriminatorColumn(name = "content_type", discriminatorType = DiscriminatorType.STRING, length = 32)
public abstract class ContentRevisionEntity extends AbstractJpaEntity {

    @Convert(converter = BusinessCodeConverter.class)
    @Column(name = "content_code", nullable = false, updatable = false, length = BusinessCode.MAX_LENGTH)
    private BusinessCode contentCode;

    @Convert(converter = RevisionNumberConverter.class)
    @Column(name = "revision_number", nullable = false, updatable = false)
    private RevisionNumber revisionNumber;

    @Enumerated(EnumType.STRING)
    @Column(name = "lifecycle", nullable = false, length = 32)
    private ContentLifecycleStatus lifecycle;

    @Convert(converter = Sha256DigestConverter.class)
    @Column(name = "checksum_sha256", nullable = false, length = Sha256Digest.LENGTH)
    private Sha256Digest checksum;

    @Column(name = "title", nullable = false, length = ContentEntityRules.TITLE_MAX_LENGTH)
    private String title;

    @Column(name = "subtitle", nullable = false, length = ContentEntityRules.SUBTITLE_MAX_LENGTH)
    private String subtitle;

    @Column(name = "description", nullable = false, length = ContentEntityRules.DESCRIPTION_MAX_LENGTH)
    private String description;

    @Convert(converter = ContentCatalogueCodeConverter.class)
    @Column(name = "category_code", nullable = false, length = CatalogueCode.MAX_LENGTH)
    private CatalogueCode categoryCode;

    @Convert(converter = ContentCatalogueCodeConverter.class)
    @Column(name = "level_code", nullable = false, length = CatalogueCode.MAX_LENGTH)
    private CatalogueCode levelCode;

    @Column(name = "minutes", nullable = false)
    private int minutes;

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(
            name = "content_revision_skill",
            schema = "app",
            joinColumns = @JoinColumn(name = "revision_id"))
    @OrderColumn(name = "position")
    @Convert(converter = ContentCatalogueCodeConverter.class)
    @Column(name = "skill_code", nullable = false, length = CatalogueCode.MAX_LENGTH)
    private List<CatalogueCode> skillCodes = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    @Column(name = "availability", nullable = false, length = 16)
    private AvailabilityStatus availability;

    @Column(name = "published_at")
    private Instant publishedAt;

    protected ContentRevisionEntity() {
    }

    protected ContentRevisionEntity(
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
            AvailabilityStatus availability) {
        this.contentCode = Objects.requireNonNull(contentCode, "contentCode");
        this.revisionNumber = Objects.requireNonNull(revisionNumber, "revisionNumber");
        this.lifecycle = ContentLifecycleStatus.DRAFT;
        replaceDraftMetadata(checksum, title, subtitle, description, categoryCode, levelCode, minutes, skillCodes);
        this.availability = Objects.requireNonNull(availability, "availability");
    }

    public abstract ContentType getContentType();

    protected abstract void validateBodyForFreeze();

    public final ContentRevisionIdentity getIdentity() {
        return new ContentRevisionIdentity(contentCode, getContentType(), revisionNumber);
    }

    public final void replaceDraftMetadata(
            Sha256Digest checksum,
            String title,
            String subtitle,
            String description,
            CatalogueCode categoryCode,
            CatalogueCode levelCode,
            int minutes,
            List<CatalogueCode> skillCodes) {
        ensureDraft();
        this.checksum = Objects.requireNonNull(checksum, "checksum");
        this.title = ContentEntityRules.requiredText(title, "title", ContentEntityRules.TITLE_MAX_LENGTH);
        this.subtitle = ContentEntityRules.requiredText(subtitle, "subtitle", ContentEntityRules.SUBTITLE_MAX_LENGTH);
        this.description = ContentEntityRules.requiredText(
                description, "description", ContentEntityRules.DESCRIPTION_MAX_LENGTH);
        this.categoryCode = Objects.requireNonNull(categoryCode, "categoryCode");
        this.levelCode = Objects.requireNonNull(levelCode, "levelCode");
        this.minutes = ContentEntityRules.positiveMinutes(minutes);
        replaceSkillCodes(ContentEntityRules.uniqueSkillCodes(skillCodes));
    }

    protected final void replaceDraftChecksum(Sha256Digest checksum) {
        ensureDraft();
        this.checksum = Objects.requireNonNull(checksum, "checksum");
    }

    public final void markReadyForAudio() {
        requireLifecycle(ContentLifecycleStatus.DRAFT);
        validateBodyForFreeze();
        this.lifecycle = ContentLifecycleStatus.READY_FOR_AUDIO;
    }

    public final void markReadyForReview() {
        requireLifecycle(ContentLifecycleStatus.READY_FOR_AUDIO);
        this.lifecycle = ContentLifecycleStatus.READY_FOR_REVIEW;
    }

    public final void publish(Instant publishedAt) {
        requireLifecycle(ContentLifecycleStatus.READY_FOR_REVIEW);
        this.publishedAt = Objects.requireNonNull(publishedAt, "publishedAt");
        this.lifecycle = ContentLifecycleStatus.PUBLISHED;
    }

    public final void archive() {
        requireLifecycle(ContentLifecycleStatus.PUBLISHED);
        this.lifecycle = ContentLifecycleStatus.ARCHIVED;
    }

    public final void changeAvailability(AvailabilityStatus availability) {
        this.availability = Objects.requireNonNull(availability, "availability");
    }

    protected final void ensureDraft() {
        if (lifecycle != null && lifecycle != ContentLifecycleStatus.DRAFT) {
            throw new IllegalStateException("Only DRAFT content revisions are editable");
        }
    }

    private void requireLifecycle(ContentLifecycleStatus expected) {
        if (lifecycle != expected) {
            throw new IllegalStateException("Expected lifecycle " + expected + " but was " + lifecycle);
        }
    }

    private void replaceSkillCodes(List<CatalogueCode> values) {
        skillCodes.clear();
        skillCodes.addAll(values);
    }

    public BusinessCode getContentCode() {
        return contentCode;
    }

    public RevisionNumber getRevisionNumber() {
        return revisionNumber;
    }

    public ContentLifecycleStatus getLifecycle() {
        return lifecycle;
    }

    public Sha256Digest getChecksum() {
        return checksum;
    }

    public String getTitle() {
        return title;
    }

    public String getSubtitle() {
        return subtitle;
    }

    public String getDescription() {
        return description;
    }

    public CatalogueCode getCategoryCode() {
        return categoryCode;
    }

    public CatalogueCode getLevelCode() {
        return levelCode;
    }

    public int getMinutes() {
        return minutes;
    }

    public List<CatalogueCode> getSkillCodes() {
        return List.copyOf(skillCodes);
    }

    public AvailabilityStatus getAvailability() {
        return availability;
    }

    public Instant getPublishedAt() {
        return publishedAt;
    }
}
