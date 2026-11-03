package io.github.alimbetov.voxprep.backend.publication.application;

import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import java.util.List;

public interface PublicationMediaValidator {

    List<PublicationValidationIssue> validate(PublicationExactContentRef ref);

    static PublicationMediaValidator noOp() {
        return ref -> List.of();
    }
}
