package io.github.alimbetov.voxprep.backend.learner.application;

import io.github.alimbetov.voxprep.backend.asset.application.LearnerMediaService;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.ContentAssetBindingRepository;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Resolves Flutter's asset-ID download route without exposing RustFS.
 * Every CURRENT binding of an asset must be accessible; a shared PREMIUM asset
 * cannot be downloaded through an alias that happens to be FREE.
 */
@Service
public class LearnerAssetResolutionService {

    private final CurrentPublicationResolver publication;
    private final ContentAssetBindingRepository bindings;
    private final LearnerContentAccessPolicy policy;
    private final LearnerMediaService media;

    public LearnerAssetResolutionService(
            CurrentPublicationResolver publication,
            ContentAssetBindingRepository bindings,
            LearnerContentAccessPolicy policy,
            LearnerMediaService media) {
        this.publication = Objects.requireNonNull(publication);
        this.bindings = Objects.requireNonNull(bindings);
        this.policy = Objects.requireNonNull(policy);
        this.media = Objects.requireNonNull(media);
    }

    @Transactional(readOnly = true)
    public LearnerMediaService.MediaDescriptor requirePublished(UUID assetId) {
        Objects.requireNonNull(assetId, "assetId");
        var exactRefs = publication.resolve().refs();
        var matches = bindings.findAllByFileAsset_Id(assetId).stream()
                .filter(binding -> exactRefs.stream().anyMatch(ref -> matches(ref, binding.getContentRevision())))
                .toList();
        if (matches.isEmpty()) {
            throw new LearnerMediaService.MediaUnavailableException("Asset is not in CURRENT publication");
        }
        for (var binding : matches) {
            if (binding.getFileAsset().getStatus() != FileAssetStatus.READY
                    || binding.getFileAsset().getKind() != binding.getRole().assetKind()) {
                throw new LearnerMediaService.MediaUnavailableException("Published asset is not READY");
            }
            var identity = binding.getContentRevision().getIdentity();
            policy.requireAccessible(identity.contentType().wireName(), identity.contentCode().value());
        }
        return media.describe(assetId);
    }

    private static boolean matches(
            PublicationExactContentRef ref,
            io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionEntity revision) {
        return ref.identity().equals(revision.getIdentity())
                && ref.checksum().equals(revision.getChecksum());
    }
}
