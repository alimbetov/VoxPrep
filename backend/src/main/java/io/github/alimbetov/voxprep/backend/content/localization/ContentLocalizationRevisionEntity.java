package io.github.alimbetov.voxprep.backend.content.localization;

import io.github.alimbetov.voxprep.backend.infrastructure.persistence.AbstractJpaEntity;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;
import java.util.Locale;
import java.util.Objects;
import java.util.UUID;

@Entity
@Table(
        name = "content_localization_revision",
        schema = "app",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_content_localization_revision__identity",
                columnNames = {"content_revision_id", "locale", "localization_revision_number"}))
public class ContentLocalizationRevisionEntity extends AbstractJpaEntity {

    @Column(name = "content_revision_id", nullable = false, updatable = false)
    private UUID contentRevisionId;

    @Column(name = "locale", nullable = false, updatable = false, length = 64)
    private String locale;

    @Column(name = "localization_revision_number", nullable = false, updatable = false)
    private int localizationRevisionNumber;

    @Enumerated(EnumType.STRING)
    @Column(name = "lifecycle", nullable = false, length = 32)
    private ContentLocalizationLifecycleStatus lifecycle;

    @Column(name = "checksum_sha256", nullable = false, length = 64)
    private String checksumSha256;

    @Column(name = "title", length = 256)
    private String title;

    @Column(name = "subtitle", length = 512)
    private String subtitle;

    @Column(name = "description", length = 4096)
    private String description;

    @Column(name = "translation", columnDefinition = "text")
    private String translation;

    @Column(name = "hint", columnDefinition = "text")
    private String hint;

    @Column(name = "explanation", columnDefinition = "text")
    private String explanation;

    @Column(name = "approved_at")
    private Instant approvedAt;

    protected ContentLocalizationRevisionEntity() {
    }

    public ContentLocalizationRevisionEntity(
            UUID contentRevisionId,
            String locale,
            int localizationRevisionNumber,
            Sha256Digest checksum,
            String title,
            String subtitle,
            String description,
            String translation,
            String hint,
            String explanation) {
        this.contentRevisionId = Objects.requireNonNull(contentRevisionId, "contentRevisionId");
        this.locale = canonicalLocale(locale);
        if (localizationRevisionNumber < 1) {
            throw new IllegalArgumentException("localizationRevisionNumber must be >= 1");
        }
        this.localizationRevisionNumber = localizationRevisionNumber;
        this.lifecycle = ContentLocalizationLifecycleStatus.DRAFT;
        replaceDraft(checksum, title, subtitle, description, translation, hint, explanation);
    }

    public void replaceDraft(
            Sha256Digest checksum,
            String title,
            String subtitle,
            String description,
            String translation,
            String hint,
            String explanation) {
        ensureDraft();
        this.checksumSha256 = Objects.requireNonNull(checksum, "checksum").value();
        this.title = optional(title);
        this.subtitle = optional(subtitle);
        this.description = optional(description);
        this.translation = optional(translation);
        this.hint = optional(hint);
        this.explanation = optional(explanation);
        if (this.title == null && this.subtitle == null && this.description == null
                && this.translation == null && this.hint == null && this.explanation == null) {
            throw new IllegalArgumentException("At least one localized field is required");
        }
    }

    public void submitForReview() {
        ensureDraft();
        lifecycle = ContentLocalizationLifecycleStatus.READY_FOR_REVIEW;
    }

    public void approve(Instant approvedAt) {
        if (lifecycle != ContentLocalizationLifecycleStatus.READY_FOR_REVIEW) {
            throw new IllegalStateException("Localization revision must be READY_FOR_REVIEW before approval");
        }
        this.approvedAt = Objects.requireNonNull(approvedAt, "approvedAt");
        lifecycle = ContentLocalizationLifecycleStatus.APPROVED;
    }

    public void ensureDraft() {
        if (lifecycle != ContentLocalizationLifecycleStatus.DRAFT) {
            throw new IllegalStateException("Only DRAFT localization revision is editable");
        }
    }

    private static String canonicalLocale(String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("locale must not be blank");
        }
        var canonical = Locale.forLanguageTag(value.trim()).toLanguageTag();
        if (canonical.equals("und")) {
            throw new IllegalArgumentException("locale must be a valid BCP-47 language tag");
        }
        return canonical;
    }

    private static String optional(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    public UUID getContentRevisionId() { return contentRevisionId; }
    public String getLocale() { return locale; }
    public int getLocalizationRevisionNumber() { return localizationRevisionNumber; }
    public ContentLocalizationLifecycleStatus getLifecycle() { return lifecycle; }
    public String getChecksumSha256() { return checksumSha256; }
    public String getTitle() { return title; }
    public String getSubtitle() { return subtitle; }
    public String getDescription() { return description; }
    public String getTranslation() { return translation; }
    public String getHint() { return hint; }
    public String getExplanation() { return explanation; }
    public Instant getApprovedAt() { return approvedAt; }
}
