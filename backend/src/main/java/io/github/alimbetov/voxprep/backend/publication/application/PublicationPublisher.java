package io.github.alimbetov.voxprep.backend.publication.application;

import io.github.alimbetov.voxprep.backend.publication.domain.PublicationCandidateStatus;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateManifestRefEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateManifestRefRepository;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateRepository;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCurrentEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCurrentRepository;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationReleaseEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationReleaseRepository;
import java.time.Instant;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PublicationPublisher {

    private final PublicationCandidateRepository candidateRepository;
    private final PublicationCandidateManifestRefRepository manifestRepository;
    private final PublicationReleaseRepository releaseRepository;
    private final PublicationCurrentRepository currentRepository;
    private final PublicationCandidateValidator validator;
    private final PublicationContentVersionAllocator versionAllocator;
    private final PublicationContentFreezer contentFreezer;
    private final PublicationWireSnapshotWriter wireWriter;

    public PublicationPublisher(
            PublicationCandidateRepository candidateRepository,
            PublicationCandidateManifestRefRepository manifestRepository,
            PublicationReleaseRepository releaseRepository,
            PublicationCurrentRepository currentRepository,
            PublicationCandidateValidator validator,
            PublicationContentVersionAllocator versionAllocator) {
        this(
                candidateRepository,
                manifestRepository,
                releaseRepository,
                currentRepository,
                validator,
                versionAllocator,
                PublicationContentFreezer.noOp(),
                PublicationWireSnapshotWriter.noOp());
    }

    public PublicationPublisher(
            PublicationCandidateRepository candidateRepository,
            PublicationCandidateManifestRefRepository manifestRepository,
            PublicationReleaseRepository releaseRepository,
            PublicationCurrentRepository currentRepository,
            PublicationCandidateValidator validator,
            PublicationContentVersionAllocator versionAllocator,
            PublicationContentFreezer contentFreezer) {
        this(candidateRepository, manifestRepository, releaseRepository, currentRepository,
                validator, versionAllocator, contentFreezer, PublicationWireSnapshotWriter.noOp());
    }

    @Autowired
    public PublicationPublisher(
            PublicationCandidateRepository candidateRepository,
            PublicationCandidateManifestRefRepository manifestRepository,
            PublicationReleaseRepository releaseRepository,
            PublicationCurrentRepository currentRepository,
            PublicationCandidateValidator validator,
            PublicationContentVersionAllocator versionAllocator,
            PublicationContentFreezer contentFreezer,
            PublicationWireSnapshotWriter wireWriter) {
        this.candidateRepository = Objects.requireNonNull(candidateRepository, "candidateRepository");
        this.manifestRepository = Objects.requireNonNull(manifestRepository, "manifestRepository");
        this.releaseRepository = Objects.requireNonNull(releaseRepository, "releaseRepository");
        this.currentRepository = Objects.requireNonNull(currentRepository, "currentRepository");
        this.validator = Objects.requireNonNull(validator, "validator");
        this.versionAllocator = Objects.requireNonNull(versionAllocator, "versionAllocator");
        this.contentFreezer = Objects.requireNonNull(contentFreezer, "contentFreezer");
        this.wireWriter = Objects.requireNonNull(wireWriter, "wireWriter");
    }

    @Transactional
    public PublicationPublishResult publish(UUID candidateId, Instant publishedAt) {
        Objects.requireNonNull(candidateId, "candidateId");
        // Flutter persists publication timestamps in second-precision Drift columns.
        // Normalize before persisting and writing the immutable root so the checksum,
        // publication metadata and HTTP representation all use the same instant.
        publishedAt = Objects.requireNonNull(publishedAt, "publishedAt")
                .truncatedTo(java.time.temporal.ChronoUnit.SECONDS);

        PublicationCandidateEntity candidate = candidateRepository.findByIdForUpdate(candidateId)
                .orElseThrow(() -> new IllegalArgumentException("publication candidate not found: " + candidateId));

        if (candidate.getStatus() == PublicationCandidateStatus.PUBLISHED) {
            PublicationReleaseEntity release = releaseRepository.findByCandidateId(candidateId)
                    .orElseThrow(() -> new IllegalStateException("published candidate has no release"));
            return result(release, true);
        }
        if (candidate.getStatus() != PublicationCandidateStatus.VALIDATED) {
            throw new IllegalStateException("only VALIDATED candidate can be published");
        }

        List<PublicationExactContentRef> manifest = manifestRepository
                .findAllByCandidateIdOrderByPositionAsc(candidateId).stream()
                .map(PublicationCandidateManifestRefEntity::toExactRef)
                .toList();
        PublicationValidationResult validation = validator.validate(manifest);
        if (!validation.valid()) {
            throw new IllegalStateException("frozen publication manifest is no longer publishable");
        }
        if (!Objects.equals(candidate.getRootSha256(), validation.rootSha256())) {
            throw new IllegalStateException("frozen publication manifest root does not match candidate root");
        }

        contentFreezer.freeze(manifest, publishedAt);

        PublicationCurrentEntity current = currentRepository.findByIdForUpdate(PublicationCurrentEntity.SINGLETON_ID)
                .orElseThrow(() -> new IllegalStateException("publication_current singleton row is missing"));

        long contentVersion = versionAllocator.nextVersion();
        PublicationReleaseEntity release = new PublicationReleaseEntity(
                candidate,
                contentVersion,
                candidate.getRootSha256(),
                publishedAt);
        releaseRepository.saveAndFlush(release);

        // Invariant: CURRENT never points to a release lacking the immutable Flutter
        // manifest, all six catalogues and a complete FREE/FULL access projection.
        wireWriter.freeze(release, manifest, publishedAt);

        current.switchTo(release, publishedAt);
        currentRepository.save(current);
        candidate.markPublished();
        candidateRepository.save(candidate);

        return result(release, false);
    }

    private static PublicationPublishResult result(PublicationReleaseEntity release, boolean replayed) {
        return new PublicationPublishResult(
                release.getContentVersion(),
                release.getRootSha256(),
                release.getPublishedAt(),
                replayed);
    }
}
