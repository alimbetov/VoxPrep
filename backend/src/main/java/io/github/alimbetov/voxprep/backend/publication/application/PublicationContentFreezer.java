package io.github.alimbetov.voxprep.backend.publication.application;

import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import java.time.Instant;
import java.util.List;

public interface PublicationContentFreezer {

    void freeze(List<PublicationExactContentRef> refs, Instant publishedAt);

    static PublicationContentFreezer noOp() {
        return (refs, publishedAt) -> { };
    }
}
