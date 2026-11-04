package io.github.alimbetov.voxprep.backend.learner.application;

import io.github.alimbetov.voxprep.backend.content.application.ContentRevisionSnapshot;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import java.util.Objects;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class LearnerContentService {

    private final CurrentPublicationResolver currentPublicationResolver;
    private final ContentRevisionRepository contentRevisionRepository;

    public LearnerContentService(
            CurrentPublicationResolver currentPublicationResolver,
            ContentRevisionRepository contentRevisionRepository) {
        this.currentPublicationResolver = Objects.requireNonNull(currentPublicationResolver, "currentPublicationResolver");
        this.contentRevisionRepository = Objects.requireNonNull(contentRevisionRepository, "contentRevisionRepository");
    }

    @Transactional(readOnly = true)
    public LearnerContentSnapshot get(String contentTypeWireName, String contentCode) {
        ContentType contentType = ContentType.fromWireName(contentTypeWireName);
        if (contentType == ContentType.QUESTION || contentType == ContentType.PRACTICE_TEST) {
            throw new IllegalArgumentException("assessment content must be requested through the learner assessment API");
        }

        CurrentPublicationSnapshot publication = currentPublicationResolver.resolve();
        PublicationExactContentRef ref = publication.refs().stream()
                .filter(value -> value.identity().contentType() == contentType)
                .filter(value -> value.identity().contentCode().value().equals(contentCode))
                .findFirst()
                .orElseThrow(() -> new LearnerContentNotFoundException(contentTypeWireName, contentCode));

        ContentRevisionEntity revision = contentRevisionRepository.findExact(ref.identity())
                .orElseThrow(() -> new IllegalStateException("published content revision is missing"));
        if (!revision.getChecksum().equals(ref.checksum())) {
            throw new IllegalStateException("published content checksum differs from publication manifest");
        }
        if (!revision.getIdentity().equals(ref.identity())) {
            throw new IllegalStateException("published content identity differs from publication manifest");
        }

        ContentRevisionSnapshot snapshot = ContentRevisionSnapshot.from(revision);
        return new LearnerContentSnapshot(
                publication.contentVersion(),
                publication.rootSha256(),
                snapshot.contentCode(),
                snapshot.contentType().wireName(),
                snapshot.revisionNumber(),
                snapshot.checksumSha256(),
                snapshot.title(),
                snapshot.subtitle(),
                snapshot.description(),
                snapshot.categoryCode(),
                snapshot.levelCode(),
                snapshot.minutes(),
                snapshot.skillCodes(),
                snapshot.body());
    }
}
