package io.github.alimbetov.voxprep.backend.learner.application;

import io.github.alimbetov.voxprep.backend.asset.application.LearnerMediaService;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.ContentAssetBindingRepository;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import java.util.List;
import java.util.Map;
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
    private final LearnerWirePublicationService publishedWire;

    public LearnerAssetResolutionService(
            CurrentPublicationResolver publication,
            ContentAssetBindingRepository bindings,
            LearnerContentAccessPolicy policy,
            LearnerMediaService media,
            LearnerWirePublicationService publishedWire) {
        this.publication = Objects.requireNonNull(publication);
        this.bindings = Objects.requireNonNull(bindings);
        this.policy = Objects.requireNonNull(policy);
        this.media = Objects.requireNonNull(media);
        this.publishedWire = Objects.requireNonNull(publishedWire);
    }

    @Transactional(readOnly = true)
    public LearnerMediaService.MediaDescriptor requirePublished(UUID assetId) {
        Objects.requireNonNull(assetId, "assetId");
        var snapshot = publication.resolve();
        var exactRefs = snapshot.refs();
        var matches = bindings.findAllByFileAsset_Id(assetId).stream()
                .filter(binding -> exactRefs.stream().anyMatch(ref -> matches(ref, binding.getContentRevision())))
                .toList();
        if (matches.isEmpty()) {
            return publishedIcon(assetId, snapshot.contentVersion());
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

    /**
     * Universal catalogue icon images are public navigation artwork for an
     * authenticated installation, not content-specific attachments. Flutter
     * requires their metadata to be present in a frozen pack descriptor.
     */
    private LearnerMediaService.MediaDescriptor publishedIcon(UUID assetId, long version) {
        var verticals = publishedWire.catalogue("verticals", Math.toIntExact(version)).body();
        if (!(verticals.get("items") instanceof List<?> items)) {
            throw new LearnerWireSnapshotUnavailableException("frozen verticals are missing");
        }
        boolean published = items.stream().anyMatch(item ->
                item instanceof Map<?, ?> vertical
                        && Boolean.TRUE.equals(vertical.get("active"))
                        && assetId.toString().equals(vertical.get("iconAssetId")));
        if (!published) {
            throw new LearnerMediaService.MediaUnavailableException("Asset is not a CURRENT vertical icon");
        }
        var descriptor = media.describe(assetId);
        if (!descriptor.mediaType().startsWith("image/")) {
            throw new LearnerMediaService.MediaUnavailableException("Catalogue icon is not an image");
        }
        var root = publishedWire.root().body();
        if (!(root.get("contentVersion") instanceof Number number)
                || number.longValue() != version
                || !(root.get("packs") instanceof List<?> packs)) {
            throw new LearnerWireSnapshotUnavailableException("frozen icon publication root is inconsistent");
        }
        for (Object item : packs) {
            if (!(item instanceof Map<?, ?> packRef)
                    || !(packRef.get("code") instanceof String code)
                    || !(packRef.get("variant") instanceof String variant)
                    || !(packRef.get("revision") instanceof Number revision)) {
                throw new LearnerWireSnapshotUnavailableException("invalid frozen pack reference");
            }
            var pack = publishedWire.pack(code, variant, revision.intValue()).body();
            if (!(pack.get("assets") instanceof List<?> assets)) {
                throw new LearnerWireSnapshotUnavailableException("frozen pack assets are missing");
            }
            for (Object raw : assets) {
                if (raw instanceof Map<?, ?> asset && assetId.toString().equals(asset.get("assetId"))) {
                    if (!descriptor.sha256().equals(asset.get("checksumSha256"))
                            || !descriptor.objectKey().equals(asset.get("deliveryKey"))
                            || !descriptor.mediaType().equals(asset.get("mediaType"))
                            || !(asset.get("sizeBytes") instanceof Number size)
                            || size.longValue() != descriptor.sizeBytes()) {
                        throw new LearnerWireSnapshotUnavailableException(
                                "catalogue icon differs from immutable media descriptor");
                    }
                    return descriptor;
                }
            }
        }
        throw new LearnerMediaService.MediaUnavailableException(
                "Catalogue icon is absent from exact published packs");
    }

    private static boolean matches(
            PublicationExactContentRef ref,
            io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionEntity revision) {
        return ref.identity().equals(revision.getIdentity())
                && ref.checksum().equals(revision.getChecksum());
    }
}
