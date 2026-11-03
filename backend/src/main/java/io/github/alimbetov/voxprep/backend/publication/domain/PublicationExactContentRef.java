package io.github.alimbetov.voxprep.backend.publication.domain;

import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.util.Objects;

/** Immutable reference to one exact content revision and its expected bytes. */
public record PublicationExactContentRef(
        ContentRevisionIdentity identity,
        Sha256Digest checksum) implements Comparable<PublicationExactContentRef> {

    public PublicationExactContentRef {
        Objects.requireNonNull(identity, "identity");
        Objects.requireNonNull(checksum, "checksum");
    }

    public String identityKey() {
        return identity.contentCode().value()
                + ":" + identity.contentType().wireName()
                + ":" + identity.revisionNumber().value();
    }

    public String canonicalKey() {
        return identityKey() + ":" + checksum.value();
    }

    @Override
    public int compareTo(PublicationExactContentRef other) {
        return canonicalKey().compareTo(other.canonicalKey());
    }
}
