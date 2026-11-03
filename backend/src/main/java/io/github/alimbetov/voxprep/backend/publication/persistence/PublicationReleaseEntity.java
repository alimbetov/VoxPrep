package io.github.alimbetov.voxprep.backend.publication.persistence;

import io.github.alimbetov.voxprep.backend.infrastructure.persistence.AbstractJpaEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.Objects;

@Entity
@Table(name = "publication_release", schema = "app")
public class PublicationReleaseEntity extends AbstractJpaEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "candidate_id", nullable = false, updatable = false)
    private PublicationCandidateEntity candidate;

    @Column(name = "content_version", nullable = false, updatable = false)
    private long contentVersion;

    @Column(name = "root_sha256", nullable = false, updatable = false, length = 64)
    private String rootSha256;

    @Column(name = "published_at", nullable = false, updatable = false)
    private Instant publishedAt;

    protected PublicationReleaseEntity() {
    }

    public PublicationReleaseEntity(
            PublicationCandidateEntity candidate,
            long contentVersion,
            String rootSha256,
            Instant publishedAt) {
        this.candidate = Objects.requireNonNull(candidate, "candidate");
        if (contentVersion <= 0) {
            throw new IllegalArgumentException("contentVersion must be positive");
        }
        this.contentVersion = contentVersion;
        this.rootSha256 = PublicationCandidateEntity.sha256(rootSha256);
        this.publishedAt = Objects.requireNonNull(publishedAt, "publishedAt");
    }

    public PublicationCandidateEntity getCandidate() {
        return candidate;
    }

    public long getContentVersion() {
        return contentVersion;
    }

    public String getRootSha256() {
        return rootSha256;
    }

    public Instant getPublishedAt() {
        return publishedAt;
    }
}
