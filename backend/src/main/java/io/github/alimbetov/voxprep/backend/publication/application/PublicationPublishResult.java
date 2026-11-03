package io.github.alimbetov.voxprep.backend.publication.application;

import java.time.Instant;

public record PublicationPublishResult(
        long contentVersion,
        String rootSha256,
        Instant publishedAt,
        boolean replayed) {
}
