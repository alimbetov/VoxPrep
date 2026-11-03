package io.github.alimbetov.voxprep.backend.publication.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.Objects;

@Entity
@Table(name = "publication_current", schema = "app")
public class PublicationCurrentEntity {

    public static final short SINGLETON_ID = 1;

    @Id
    @Column(name = "singleton_id", nullable = false, updatable = false)
    private short singletonId;

    @Version
    @Column(name = "version", nullable = false)
    private long version;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "release_id")
    private PublicationReleaseEntity release;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected PublicationCurrentEntity() {
    }

    public void switchTo(PublicationReleaseEntity release, Instant updatedAt) {
        this.release = Objects.requireNonNull(release, "release");
        this.updatedAt = Objects.requireNonNull(updatedAt, "updatedAt");
    }

    public short getSingletonId() {
        return singletonId;
    }

    public long getVersion() {
        return version;
    }

    public PublicationReleaseEntity getRelease() {
        return release;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
