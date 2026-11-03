package io.github.alimbetov.voxprep.backend.learner.application;

import io.github.alimbetov.voxprep.backend.publication.domain.PublicationCandidateStatus;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateManifestRefRepository;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCurrentEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCurrentRepository;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationReleaseEntity;
import java.util.List;
import java.util.Objects;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CurrentPublicationResolver {

    private final PublicationCurrentRepository currentRepository;
    private final PublicationCandidateManifestRefRepository manifestRepository;

    public CurrentPublicationResolver(
            PublicationCurrentRepository currentRepository,
            PublicationCandidateManifestRefRepository manifestRepository) {
        this.currentRepository = Objects.requireNonNull(currentRepository, "currentRepository");
        this.manifestRepository = Objects.requireNonNull(manifestRepository, "manifestRepository");
    }

    @Transactional(readOnly = true)
    public CurrentPublicationSnapshot resolve() {
        PublicationCurrentEntity current = currentRepository.findById(PublicationCurrentEntity.SINGLETON_ID)
                .orElseThrow(() -> new IllegalStateException("publication_current singleton is missing"));

        PublicationReleaseEntity release = current.getRelease();
        if (release == null) {
            throw new IllegalStateException("no publication is currently active");
        }

        PublicationCandidateEntity candidate = release.getCandidate();
        if (candidate.getStatus() != PublicationCandidateStatus.PUBLISHED) {
            throw new IllegalStateException("current release candidate is not PUBLISHED");
        }
        if (!release.getRootSha256().equals(candidate.getRootSha256())) {
            throw new IllegalStateException("current release root differs from candidate root");
        }

        List<PublicationExactContentRef> refs = manifestRepository
                .findAllByCandidateIdOrderByPositionAsc(candidate.getId())
                .stream()
                .map(entity -> entity.toExactRef())
                .toList();
        if (refs.isEmpty()) {
            throw new IllegalStateException("current publication manifest is empty");
        }

        return new CurrentPublicationSnapshot(
                release.getContentVersion(),
                release.getRootSha256(),
                release.getPublishedAt(),
                refs);
    }
}
