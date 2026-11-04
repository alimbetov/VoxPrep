package io.github.alimbetov.voxprep.backend.catalogue.domain;

public final class CatalogueConstraints {

    public static final int CODE_MAX_LENGTH = 128;
    public static final String CODE_PATTERN = "^[A-Z0-9][A-Z0-9._-]*$";
    public static final int TITLE_MAX_LENGTH = 256;
    public static final int DESCRIPTION_MAX_LENGTH = 4096;
    public static final int EXTERNAL_ID_MAX_LENGTH = 256;

    private CatalogueConstraints() {
    }
}
