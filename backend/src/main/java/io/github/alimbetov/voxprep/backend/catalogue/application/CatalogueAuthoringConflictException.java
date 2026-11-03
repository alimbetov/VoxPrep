package io.github.alimbetov.voxprep.backend.catalogue.application;

public final class CatalogueAuthoringConflictException extends RuntimeException {

    public CatalogueAuthoringConflictException(String message) {
        super(message);
    }

    public CatalogueAuthoringConflictException(String message, Throwable cause) {
        super(message, cause);
    }
}
