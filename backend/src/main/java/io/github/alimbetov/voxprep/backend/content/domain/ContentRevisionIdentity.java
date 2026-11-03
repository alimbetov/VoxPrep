package io.github.alimbetov.voxprep.backend.content.domain;

import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import java.util.Objects;

public record ContentRevisionIdentity(
        BusinessCode contentCode,
        ContentType contentType,
        RevisionNumber revisionNumber) {

    public ContentRevisionIdentity {
        Objects.requireNonNull(contentCode, "contentCode");
        Objects.requireNonNull(contentType, "contentType");
        Objects.requireNonNull(revisionNumber, "revisionNumber");
    }
}
