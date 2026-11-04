package io.github.alimbetov.voxprep.backend.publication.application;

import java.util.List;
import java.util.Objects;

public record PublicationValidationResult(
        List<String> canonicalRefs,
        List<PublicationValidationIssue> issues,
        String rootSha256) {

    public PublicationValidationResult {
        canonicalRefs = List.copyOf(Objects.requireNonNull(canonicalRefs, "canonicalRefs"));
        issues = List.copyOf(Objects.requireNonNull(issues, "issues"));
        if (issues.stream().anyMatch(issue -> issue.severity() == PublicationValidationSeverity.ERROR)
                && rootSha256 != null) {
            throw new IllegalArgumentException("invalid validation result cannot have rootSha256");
        }
    }

    public boolean valid() {
        return issues.stream().noneMatch(issue -> issue.severity() == PublicationValidationSeverity.ERROR);
    }

    public boolean hasWarnings() {
        return issues.stream().anyMatch(issue -> issue.severity() == PublicationValidationSeverity.WARNING);
    }
}
