package io.github.alimbetov.voxprep.backend.learner.application;

import java.time.Instant;
import java.util.List;
import java.util.Objects;

public record LearnerCatalogueSnapshot(
        long contentVersion,
        String rootSha256,
        Instant publishedAt,
        List<LearnerCatalogueEntry> entries) {

    public LearnerCatalogueSnapshot {
        if (contentVersion <= 0) {
            throw new IllegalArgumentException("contentVersion must be positive");
        }
        Objects.requireNonNull(rootSha256, "rootSha256");
        Objects.requireNonNull(publishedAt, "publishedAt");
        entries = List.copyOf(Objects.requireNonNull(entries, "entries"));
        if (entries.isEmpty()) {
            throw new IllegalArgumentException("learner catalogue must not be empty");
        }
    }
}
