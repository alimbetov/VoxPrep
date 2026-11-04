package io.github.alimbetov.voxprep.backend.publication.application;

import java.util.Objects;

public record PublicationValidationIssue(
        PublicationValidationSeverity severity,
        PublicationValidationCode code,
        String refKey,
        String detail) implements Comparable<PublicationValidationIssue> {

    public PublicationValidationIssue(
            PublicationValidationCode code,
            String refKey,
            String detail) {
        this(PublicationValidationSeverity.ERROR, code, refKey, detail);
    }

    public PublicationValidationIssue {
        Objects.requireNonNull(severity, "severity");
        Objects.requireNonNull(code, "code");
        refKey = refKey == null ? "" : refKey;
        detail = detail == null ? "" : detail;
    }

    @Override
    public int compareTo(PublicationValidationIssue other) {
        int bySeverity = severity.name().compareTo(other.severity.name());
        if (bySeverity != 0) {
            return bySeverity;
        }
        int byCode = code.name().compareTo(other.code.name());
        if (byCode != 0) {
            return byCode;
        }
        int byRef = refKey.compareTo(other.refKey);
        return byRef != 0 ? byRef : detail.compareTo(other.detail);
    }
}
