package io.github.alimbetov.voxprep.backend.publication.application;

public enum PublicationValidationCode {
    EMPTY_CANDIDATE,
    DUPLICATE_REF,
    MISSING_REVISION,
    CHECKSUM_MISMATCH,
    NOT_PUBLISHABLE
}
