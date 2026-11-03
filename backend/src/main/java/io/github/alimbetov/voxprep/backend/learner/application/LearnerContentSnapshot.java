package io.github.alimbetov.voxprep.backend.learner.application;

import io.github.alimbetov.voxprep.backend.content.application.ContentRevisionSnapshot;
import java.util.List;
import java.util.Objects;

public record LearnerContentSnapshot(
        long contentVersion,
        String rootSha256,
        String contentCode,
        String contentType,
        int revisionNumber,
        String checksumSha256,
        String title,
        String subtitle,
        String description,
        String categoryCode,
        String levelCode,
        int minutes,
        List<String> skillCodes,
        ContentRevisionSnapshot.Body body) {

    public LearnerContentSnapshot {
        if (contentVersion <= 0) {
            throw new IllegalArgumentException("contentVersion must be positive");
        }
        Objects.requireNonNull(rootSha256, "rootSha256");
        Objects.requireNonNull(contentCode, "contentCode");
        Objects.requireNonNull(contentType, "contentType");
        Objects.requireNonNull(checksumSha256, "checksumSha256");
        Objects.requireNonNull(title, "title");
        Objects.requireNonNull(subtitle, "subtitle");
        Objects.requireNonNull(description, "description");
        Objects.requireNonNull(categoryCode, "categoryCode");
        Objects.requireNonNull(levelCode, "levelCode");
        skillCodes = List.copyOf(Objects.requireNonNull(skillCodes, "skillCodes"));
        Objects.requireNonNull(body, "body");
    }
}
