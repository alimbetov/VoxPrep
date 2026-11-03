package io.github.alimbetov.voxprep.backend.content.application;

import java.util.UUID;

public final class ContentRevisionNotFoundException extends RuntimeException {

    public ContentRevisionNotFoundException(UUID revisionId) {
        super("Content revision not found: " + revisionId);
    }
}
