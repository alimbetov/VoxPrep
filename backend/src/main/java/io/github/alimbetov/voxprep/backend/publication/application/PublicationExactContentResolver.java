package io.github.alimbetov.voxprep.backend.publication.application;

import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.util.Objects;
import java.util.Optional;

public interface PublicationExactContentResolver {

    Optional<ResolvedContentRevision> resolveExact(ContentRevisionIdentity identity);

    record ResolvedContentRevision(
            ContentRevisionIdentity identity,
            Sha256Digest checksum,
            ContentLifecycleStatus lifecycle) {

        public ResolvedContentRevision {
            Objects.requireNonNull(identity, "identity");
            Objects.requireNonNull(checksum, "checksum");
            Objects.requireNonNull(lifecycle, "lifecycle");
        }
    }
}
