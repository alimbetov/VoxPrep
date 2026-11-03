package io.github.alimbetov.voxprep.backend.publication.persistence;

import io.github.alimbetov.voxprep.backend.infrastructure.persistence.AbstractJpaEntity;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationCandidateStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.Objects;

@Entity
@Table(name = "publication_candidate", schema = "app")
public class PublicationCandidateEntity extends AbstractJpaEntity {

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 32)
    private PublicationCandidateStatus status;

    @Column(name = "root_sha256", length = 64)
    private String rootSha256;

    @Column(name = "validated_at")
    private Instant validatedAt;

    protected PublicationCandidateEntity() {
    }

    public PublicationCandidateEntity(PublicationCandidateStatus status) {
        this.status = Objects.requireNonNull(status, "status");
        if (status != PublicationCandidateStatus.DRAFT) {
            throw new IllegalArgumentException("new publication candidate must start as DRAFT");
        }
    }

    public void markValidated(String rootSha256, Instant validatedAt) {
        if (status != PublicationCandidateStatus.DRAFT) {
            throw new IllegalStateException("only DRAFT candidate can be validated");
        }
        this.rootSha256 = sha256(rootSha256);
        this.validatedAt = Objects.requireNonNull(validatedAt, "validatedAt");
        this.status = PublicationCandidateStatus.VALIDATED;
    }

    public void markRejected() {
        if (status == PublicationCandidateStatus.PUBLISHED) {
            throw new IllegalStateException("published candidate cannot be rejected");
        }
        this.status = PublicationCandidateStatus.REJECTED;
    }

    public void markPublished() {
        if (status != PublicationCandidateStatus.VALIDATED) {
            throw new IllegalStateException("only VALIDATED candidate can be published");
        }
        this.status = PublicationCandidateStatus.PUBLISHED;
    }

    public PublicationCandidateStatus getStatus() {
        return status;
    }

    public String getRootSha256() {
        return rootSha256;
    }

    public Instant getValidatedAt() {
        return validatedAt;
    }

    static String sha256(String value) {
        Objects.requireNonNull(value, "rootSha256");
        if (!value.matches("[0-9a-f]{64}")) {
            throw new IllegalArgumentException("rootSha256 must be lowercase SHA-256");
        }
        return value;
    }
}
