package io.github.alimbetov.voxprep.backend.publication.application;

public enum PublicationValidationCode {
    EMPTY_CANDIDATE,
    DUPLICATE_REF,
    MISSING_REVISION,
    CHECKSUM_MISMATCH,
    NOT_PUBLISHABLE,
    MISSING_REQUIRED_AUDIO,
    MISSING_RECOMMENDED_AUDIO,
    STALE_AUDIO,
    INVALID_AUDIO_BINDING,
    INVALID_IMAGE_BINDING
}
