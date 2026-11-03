package io.github.alimbetov.voxprep.backend.publication.application;

import java.util.Objects;

public record PublicationValidationIssue(
        PublicationValidationCode code,
        String refKey,
        String detail) implements Comparable<PublicationValidationIssue> {

    public PublicationValidationIssue {
        Objects.requireNonNull(code, "code");
        refKey = refKey == null ? "" : refKey;
        detail = detail == null ? "" : detail;
    }

    @Override
    public int compareTo(PublicationValidationIssue other) {
        int byCode = code.name().compareTo(other.code.name());
        if (byCode != 0) {
            return byCode;
        }
        int byRef = refKey.compareTo(other.refKey);
        return byRef != 0 ? byRef : detail.compareTo(other.detail);
    }
}
