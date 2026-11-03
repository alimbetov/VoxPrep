package io.github.alimbetov.voxprep.backend.content.application;

public final class ContentAuthoringConflictException extends RuntimeException {

    public ContentAuthoringConflictException(String message) {
        super(message);
    }

    public ContentAuthoringConflictException(String message, Throwable cause) {
        super(message, cause);
    }
}
