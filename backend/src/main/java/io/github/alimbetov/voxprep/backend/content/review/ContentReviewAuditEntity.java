package io.github.alimbetov.voxprep.backend.content.review;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

@Entity
@Table(name = "content_review_audit", schema = "app")
public class ContentReviewAuditEntity {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "content_revision_id", nullable = false, updatable = false)
    private UUID contentRevisionId;

    @Enumerated(EnumType.STRING)
    @Column(name = "action", nullable = false, updatable = false, length = 32)
    private ContentReviewAction action;

    @Column(name = "actor", nullable = false, updatable = false, length = 128)
    private String actor;

    @Column(name = "reason", updatable = false, length = 512)
    private String reason;

    @Column(name = "comment", updatable = false, length = 2048)
    private String comment;

    @Column(name = "occurred_at", nullable = false, updatable = false)
    private Instant occurredAt;

    protected ContentReviewAuditEntity() {
    }

    public ContentReviewAuditEntity(
            UUID contentRevisionId,
            ContentReviewAction action,
            String actor,
            String reason,
            String comment,
            Instant occurredAt) {
        this.id = UUID.randomUUID();
        this.contentRevisionId = Objects.requireNonNull(contentRevisionId, "contentRevisionId");
        this.action = Objects.requireNonNull(action, "action");
        this.actor = requiredText(actor, "actor");
        this.reason = optionalText(reason);
        this.comment = optionalText(comment);
        this.occurredAt = Objects.requireNonNull(occurredAt, "occurredAt");
    }

    private static String requiredText(String value, String field) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(field + " must not be blank");
        }
        return value.trim();
    }

    private static String optionalText(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    public UUID getId() {
        return id;
    }

    public UUID getContentRevisionId() {
        return contentRevisionId;
    }

    public ContentReviewAction getAction() {
        return action;
    }

    public String getActor() {
        return actor;
    }

    public String getReason() {
        return reason;
    }

    public String getComment() {
        return comment;
    }

    public Instant getOccurredAt() {
        return occurredAt;
    }
}
