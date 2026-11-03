package io.github.alimbetov.voxprep.backend.catalogue.application;

import java.util.UUID;

public final class CatalogueAuthoringNotFoundException extends RuntimeException {

    public CatalogueAuthoringNotFoundException(String type, UUID id) {
        super(type + " not found: " + id);
    }
}
