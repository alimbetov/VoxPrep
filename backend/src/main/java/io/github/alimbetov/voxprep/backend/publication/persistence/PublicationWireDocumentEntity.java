package io.github.alimbetov.voxprep.backend.publication.persistence;

import io.github.alimbetov.voxprep.backend.infrastructure.persistence.AbstractJpaEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.util.Objects;

@Entity
@Table(
        name = "publication_wire_document",
        schema = "app",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_publication_wire_document__identity",
                columnNames = {"release_id", "document_kind", "resource_code", "variant", "revision"}))
public class PublicationWireDocumentEntity extends AbstractJpaEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "release_id", nullable = false, updatable = false)
    private PublicationReleaseEntity release;

    @Enumerated(EnumType.STRING)
    @Column(name = "document_kind", nullable = false, updatable = false, length = 16)
    private PublicationWireDocumentKind kind;

    @Column(name = "resource_code", nullable = false, updatable = false, length = 128)
    private String resourceCode;

    @Column(name = "variant", nullable = false, updatable = false, length = 64)
    private String variant;

    @Column(name = "revision", nullable = false, updatable = false)
    private long revision;

    @Column(name = "checksum_sha256", nullable = false, updatable = false, length = 64)
    private String checksumSha256;

    @Column(name = "body_json", nullable = false, updatable = false, columnDefinition = "text")
    private String bodyJson;

    protected PublicationWireDocumentEntity() {
    }

    public PublicationWireDocumentEntity(
            PublicationReleaseEntity release,
            PublicationWireDocumentKind kind,
            String resourceCode,
            String variant,
            long revision,
            String checksumSha256,
            String bodyJson) {
        this.release = Objects.requireNonNull(release);
        this.kind = Objects.requireNonNull(kind);
        this.resourceCode = nonBlank(resourceCode, "resourceCode", 128);
        this.variant = nonBlank(variant, "variant", 64);
        if (revision < 1) {
            throw new IllegalArgumentException("revision must be positive");
        }
        this.revision = revision;
        if (checksumSha256 == null || !checksumSha256.matches("[0-9a-f]{64}")) {
            throw new IllegalArgumentException("checksumSha256 must be a lowercase SHA-256 digest");
        }
        this.checksumSha256 = checksumSha256;
        this.bodyJson = nonBlank(bodyJson, "bodyJson", 16_777_216);
    }

    public PublicationReleaseEntity getRelease() { return release; }
    public PublicationWireDocumentKind getKind() { return kind; }
    public String getResourceCode() { return resourceCode; }
    public String getVariant() { return variant; }
    public long getRevision() { return revision; }
    public String getChecksumSha256() { return checksumSha256; }
    public String getBodyJson() { return bodyJson; }

    private static String nonBlank(String value, String field, int maxLength) {
        if (value == null || value.isBlank() || value.length() > maxLength) {
            throw new IllegalArgumentException(field + " must be nonblank and within length limit");
        }
        return value;
    }
}
