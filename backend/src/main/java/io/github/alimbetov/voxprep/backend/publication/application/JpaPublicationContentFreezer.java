package io.github.alimbetov.voxprep.backend.publication.application;

import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import java.time.Instant;
import java.util.List;
import java.util.Objects;
import org.springframework.stereotype.Component;

@Component
public class JpaPublicationContentFreezer implements PublicationContentFreezer {

    private final ContentRevisionRepository contentRevisionRepository;

    public JpaPublicationContentFreezer(ContentRevisionRepository contentRevisionRepository) {
        this.contentRevisionRepository = Objects.requireNonNull(contentRevisionRepository, "contentRevisionRepository");
    }

    @Override
    public void freeze(List<PublicationExactContentRef> refs, Instant publishedAt) {
        Objects.requireNonNull(refs, "refs");
        Objects.requireNonNull(publishedAt, "publishedAt");
        for (PublicationExactContentRef ref : refs) {
            var revision = contentRevisionRepository.findExact(ref.identity())
                    .orElseThrow(() -> new IllegalStateException(
                            "validated publication revision disappeared: " + ref.identityKey()));
            if (!revision.getChecksum().equals(ref.checksum())) {
                throw new IllegalStateException(
                        "validated publication revision checksum changed: " + ref.identityKey());
            }
            if (revision.getLifecycle() == ContentLifecycleStatus.APPROVED) {
                revision.publish(publishedAt);
                contentRevisionRepository.save(revision);
            } else if (revision.getLifecycle() != ContentLifecycleStatus.PUBLISHED) {
                throw new IllegalStateException(
                        "validated publication revision is no longer publishable: " + ref.identityKey());
            }
        }
    }
}
