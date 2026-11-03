package io.github.alimbetov.voxprep.backend.learner.application;

import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import java.util.Objects;

public record LearnerCatalogueEntry(
        String contentCode,
        String contentType,
        int revisionNumber,
        String checksumSha256) {

    public LearnerCatalogueEntry {
        Objects.requireNonNull(contentCode, "contentCode");
        Objects.requireNonNull(contentType, "contentType");
        Objects.requireNonNull(checksumSha256, "checksumSha256");
        if (revisionNumber <= 0) {
            throw new IllegalArgumentException("revisionNumber must be positive");
        }
    }

    public static LearnerCatalogueEntry from(PublicationExactContentRef ref) {
        Objects.requireNonNull(ref, "ref");
        return new LearnerCatalogueEntry(
                ref.identity().contentCode().value(),
                ref.identity().contentType().wireName(),
                ref.identity().revisionNumber().value(),
                ref.checksum().value());
    }
}
