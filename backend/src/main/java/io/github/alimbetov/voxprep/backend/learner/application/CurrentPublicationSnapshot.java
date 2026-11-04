package io.github.alimbetov.voxprep.backend.learner.application;

import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import java.time.Instant;
import java.util.List;
import java.util.Objects;

public record CurrentPublicationSnapshot(
        long contentVersion,
        String rootSha256,
        Instant publishedAt,
        List<PublicationExactContentRef> refs) {

    public CurrentPublicationSnapshot {
        if (contentVersion <= 0) {
            throw new IllegalArgumentException("contentVersion must be positive");
        }
        Objects.requireNonNull(rootSha256, "rootSha256");
        if (!rootSha256.matches("[0-9a-f]{64}")) {
            throw new IllegalArgumentException("rootSha256 must be lowercase SHA-256");
        }
        Objects.requireNonNull(publishedAt, "publishedAt");
        refs = List.copyOf(Objects.requireNonNull(refs, "refs"));
        if (refs.isEmpty()) {
            throw new IllegalArgumentException("current publication manifest must not be empty");
        }
    }
}
