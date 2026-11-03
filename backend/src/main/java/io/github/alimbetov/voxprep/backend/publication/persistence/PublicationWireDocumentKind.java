package io.github.alimbetov.voxprep.backend.publication.persistence;

/** Distinct immutable wire artefacts, not the legacy candidate-ref digest. */
public enum PublicationWireDocumentKind {
    ROOT,
    PACK,
    CATALOGUE
}
