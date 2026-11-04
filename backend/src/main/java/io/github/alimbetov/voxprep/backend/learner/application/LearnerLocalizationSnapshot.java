package io.github.alimbetov.voxprep.backend.learner.application;

import java.util.Objects;

public record LearnerLocalizationSnapshot(
        long contentVersion,
        String rootSha256,
        String contentCode,
        String contentType,
        int revisionNumber,
        String requestedLocale,
        String resolvedLocale,
        String fallback,
        Integer localizationRevisionNumber,
        String localizationChecksumSha256,
        String title,
        String subtitle,
        String description,
        String translation,
        String hint,
        String explanation) {

    public LearnerLocalizationSnapshot {
        if (contentVersion <= 0) {
            throw new IllegalArgumentException("contentVersion must be positive");
        }
        Objects.requireNonNull(rootSha256, "rootSha256");
        Objects.requireNonNull(contentCode, "contentCode");
        Objects.requireNonNull(contentType, "contentType");
        Objects.requireNonNull(requestedLocale, "requestedLocale");
        Objects.requireNonNull(fallback, "fallback");
        Objects.requireNonNull(title, "title");
        Objects.requireNonNull(subtitle, "subtitle");
        Objects.requireNonNull(description, "description");
    }
}
