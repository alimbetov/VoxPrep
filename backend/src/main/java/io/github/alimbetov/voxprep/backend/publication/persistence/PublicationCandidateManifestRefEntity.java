package io.github.alimbetov.voxprep.backend.publication.persistence;

import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.infrastructure.persistence.AbstractJpaEntity;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.util.Objects;
import java.util.UUID;

@Entity
@Table(
        name = "publication_candidate_manifest_ref",
        schema = "app",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_pub_candidate_manifest__position", columnNames = {"candidate_id", "position"}),
                @UniqueConstraint(
                        name = "uk_pub_candidate_manifest__identity",
                        columnNames = {"candidate_id", "content_code", "content_type", "revision_number"})
        })
public class PublicationCandidateManifestRefEntity extends AbstractJpaEntity {

    @Column(name = "candidate_id", nullable = false, updatable = false)
    private UUID candidateId;

    @Column(name = "position", nullable = false, updatable = false)
    private int position;

    @Column(name = "content_code", nullable = false, updatable = false, length = BusinessCode.MAX_LENGTH)
    private String contentCode;

    @Column(name = "content_type", nullable = false, updatable = false, length = 32)
    private String contentType;

    @Column(name = "revision_number", nullable = false, updatable = false)
    private int revisionNumber;

    @Column(name = "checksum_sha256", nullable = false, updatable = false, length = Sha256Digest.LENGTH)
    private String checksumSha256;

    protected PublicationCandidateManifestRefEntity() {
    }

    public PublicationCandidateManifestRefEntity(UUID candidateId, int position, PublicationExactContentRef ref) {
        this.candidateId = Objects.requireNonNull(candidateId, "candidateId");
        if (position < 0) {
            throw new IllegalArgumentException("position must be >= 0");
        }
        Objects.requireNonNull(ref, "ref");
        this.position = position;
        this.contentCode = ref.identity().contentCode().value();
        this.contentType = ref.identity().contentType().wireName();
        this.revisionNumber = ref.identity().revisionNumber().value();
        this.checksumSha256 = ref.checksum().value();
    }

    public PublicationExactContentRef toExactRef() {
        return new PublicationExactContentRef(
                new ContentRevisionIdentity(
                        new BusinessCode(contentCode),
                        ContentType.fromWireName(contentType),
                        new RevisionNumber(revisionNumber)),
                new Sha256Digest(checksumSha256));
    }

    public UUID getCandidateId() {
        return candidateId;
    }

    public int getPosition() {
        return position;
    }
}
