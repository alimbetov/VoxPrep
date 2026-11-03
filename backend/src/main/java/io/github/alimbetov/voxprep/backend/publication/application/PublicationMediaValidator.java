package io.github.alimbetov.voxprep.backend.publication.application;

import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionEntity;
import java.util.List;

public interface PublicationMediaValidator {

    List<PublicationValidationIssue> validate(ContentRevisionEntity revision);

    static PublicationMediaValidator noOp() {
        return revision -> List.of();
    }
}
