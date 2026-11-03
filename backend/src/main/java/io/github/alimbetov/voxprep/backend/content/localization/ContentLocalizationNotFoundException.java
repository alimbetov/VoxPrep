package io.github.alimbetov.voxprep.backend.content.localization;

import java.util.UUID;

public final class ContentLocalizationNotFoundException extends RuntimeException {

    public ContentLocalizationNotFoundException(UUID id) {
        super("Content localization revision not found: " + id);
    }
}
