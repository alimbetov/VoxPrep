package io.github.alimbetov.voxprep.backend.tts.domain;

public enum TtsVoiceModelStatus {
    UPLOADING,
    UPLOADED,
    VALIDATING,
    READY_FOR_REVIEW,
    APPROVED,
    ACTIVE,
    DEPRECATED,
    INVALID,
    QUARANTINED
}
