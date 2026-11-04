package io.github.alimbetov.voxprep.backend.publication.application;

import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationReleaseEntity;
import java.time.Instant;
import java.util.List;

/**
 * Atomically freezes all Flutter-facing wire documents for one release.
 * Called in the publishing transaction BEFORE the CURRENT pointer advances.
 */
public interface PublicationWireSnapshotWriter {

    void freeze(PublicationReleaseEntity release, List<PublicationExactContentRef> refs, Instant publishedAt);

    /** Test-only legacy constructor compatibility; never wired into Spring production. */
    static PublicationWireSnapshotWriter noOp() {
        return (release, refs, publishedAt) -> {};
    }
}
