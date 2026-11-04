package io.github.alimbetov.voxprep.backend.learner.application;

import io.github.alimbetov.voxprep.backend.asset.application.LearnerMediaService;
import io.github.alimbetov.voxprep.backend.asset.domain.ContentAssetRole;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.ContentAssetBindingEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.ContentAssetBindingRepository;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsJobRepository;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class LearnerPublishedMediaService {

    private final CurrentPublicationResolver currentPublicationResolver;
    private final ContentRevisionRepository contentRevisionRepository;
    private final ContentAssetBindingRepository bindingRepository;
    private final TtsJobRepository ttsJobRepository;
    private final LearnerMediaService learnerMediaService;

    public LearnerPublishedMediaService(
            CurrentPublicationResolver currentPublicationResolver,
            ContentRevisionRepository contentRevisionRepository,
            ContentAssetBindingRepository bindingRepository,
            TtsJobRepository ttsJobRepository,
            LearnerMediaService learnerMediaService) {
        this.currentPublicationResolver = Objects.requireNonNull(currentPublicationResolver, "currentPublicationResolver");
        this.contentRevisionRepository = Objects.requireNonNull(contentRevisionRepository, "contentRevisionRepository");
        this.bindingRepository = Objects.requireNonNull(bindingRepository, "bindingRepository");
        this.ttsJobRepository = Objects.requireNonNull(ttsJobRepository, "ttsJobRepository");
        this.learnerMediaService = Objects.requireNonNull(learnerMediaService, "learnerMediaService");
    }

    @Transactional(readOnly = true)
    public List<MediaAssetSnapshot> listMedia(String contentTypeWireName, String contentCode) {
        PublishedRevision publishedRevision = requirePublishedRevision(contentTypeWireName, contentCode);
        return bindingRepository.findAllByContentRevision_IdOrderByRoleAsc(publishedRevision.revision().getId()).stream()
                .map(this::toMediaAsset)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<AudioAssetSnapshot> listAudio(String contentTypeWireName, String contentCode) {
        PublishedRevision publishedRevision = requirePublishedRevision(contentTypeWireName, contentCode);
        return bindingRepository.findAllByContentRevision_IdOrderByRoleAsc(publishedRevision.revision().getId()).stream()
                .filter(binding -> binding.getRole().audio())
                .map(this::toAudioAsset)
                .toList();
    }

    @Transactional(readOnly = true)
    public LearnerMediaService.MediaDescriptor requireMedia(
            String contentTypeWireName,
            String contentCode,
            UUID assetId) {
        Objects.requireNonNull(assetId, "assetId");
        PublishedRevision publishedRevision = requirePublishedRevision(contentTypeWireName, contentCode);
        ContentAssetBindingEntity binding = bindingRepository
                .findAllByContentRevision_IdOrderByRoleAsc(publishedRevision.revision().getId()).stream()
                .filter(value -> assetId.equals(value.getFileAsset().getId()))
                .findFirst()
                .orElseThrow(() -> new LearnerMediaService.MediaUnavailableException("Published media asset not found"));
        ensureDeliverable(binding);
        return learnerMediaService.describe(assetId);
    }

    @Transactional(readOnly = true)
    public LearnerMediaService.MediaDescriptor requireAudio(
            String contentTypeWireName,
            String contentCode,
            UUID assetId) {
        PublishedRevision publishedRevision = requirePublishedRevision(contentTypeWireName, contentCode);
        ContentAssetBindingEntity binding = bindingRepository
                .findAllByContentRevision_IdOrderByRoleAsc(publishedRevision.revision().getId()).stream()
                .filter(value -> value.getRole().audio())
                .filter(value -> assetId.equals(value.getFileAsset().getId()))
                .findFirst()
                .orElseThrow(() -> new LearnerMediaService.MediaUnavailableException("Published audio asset not found"));
        ensureDeliverable(binding);
        return learnerMediaService.describe(assetId);
    }

    public LearnerMediaService.MediaContent read(LearnerMediaService.MediaDescriptor descriptor) {
        return learnerMediaService.read(descriptor);
    }

    private PublishedRevision requirePublishedRevision(String contentTypeWireName, String contentCode) {
        ContentType contentType = ContentType.fromWireName(contentTypeWireName);
        CurrentPublicationSnapshot publication = currentPublicationResolver.resolve();
        PublicationExactContentRef ref = publication.refs().stream()
                .filter(value -> value.identity().contentType() == contentType)
                .filter(value -> value.identity().contentCode().value().equals(contentCode))
                .findFirst()
                .orElseThrow(() -> new LearnerContentNotFoundException(contentTypeWireName, contentCode));

        ContentRevisionEntity revision = contentRevisionRepository.findExact(ref.identity())
                .orElseThrow(() -> new IllegalStateException("published content revision is missing"));
        if (!revision.getIdentity().equals(ref.identity())) {
            throw new IllegalStateException("published content identity differs from publication manifest");
        }
        if (!revision.getChecksum().equals(ref.checksum())) {
            throw new IllegalStateException("published content checksum differs from publication manifest");
        }
        return new PublishedRevision(publication, ref, revision);
    }

    private MediaAssetSnapshot toMediaAsset(ContentAssetBindingEntity binding) {
        ensureDeliverable(binding);
        FileAssetEntity asset = binding.getFileAsset();
        LearnerMediaService.MediaDescriptor descriptor = learnerMediaService.describe(asset.getId());
        return new MediaAssetSnapshot(
                descriptor.assetId(),
                binding.getRole().wireName(),
                asset.getKind().name(),
                descriptor.mediaType(),
                descriptor.sizeBytes(),
                descriptor.sha256(),
                descriptor.etag());
    }

    private AudioAssetSnapshot toAudioAsset(ContentAssetBindingEntity binding) {
        if (!binding.getRole().audio()) {
            throw new IllegalArgumentException("Content asset binding is not audio");
        }
        ensureDeliverable(binding);
        FileAssetEntity asset = binding.getFileAsset();
        LearnerMediaService.MediaDescriptor descriptor = learnerMediaService.describe(asset.getId());
        String language = binding.getSourceFingerprint() == null
                ? null
                : ttsJobRepository.findByFingerprint(binding.getSourceFingerprint())
                        .map(job -> job.getLanguage())
                        .orElse(null);
        return new AudioAssetSnapshot(
                descriptor.assetId(),
                binding.getRole().wireName(),
                language,
                descriptor.mediaType(),
                descriptor.sizeBytes(),
                descriptor.sha256(),
                descriptor.etag());
    }

    private static void ensureDeliverable(ContentAssetBindingEntity binding) {
        FileAssetEntity asset = binding.getFileAsset();
        ContentAssetRole role = binding.getRole();
        if (asset.getStatus() != FileAssetStatus.READY || asset.getKind() != role.assetKind()) {
            throw new IllegalStateException("published media binding is not deliverable");
        }
        if (role.audio()) {
            if (asset.getKind() != FileAssetKind.TTS_AUDIO
                    || !asset.getMediaType().startsWith("audio/")
                    || binding.getSourceFingerprint() == null) {
                throw new IllegalStateException("published audio binding is invalid");
            }
        } else if (!asset.getMediaType().startsWith("image/") || binding.getSourceFingerprint() != null) {
            throw new IllegalStateException("published image binding is invalid");
        }
    }

    private record PublishedRevision(
            CurrentPublicationSnapshot publication,
            PublicationExactContentRef ref,
            ContentRevisionEntity revision) {
    }

    public record MediaAssetSnapshot(
            UUID assetId,
            String role,
            String kind,
            String mediaType,
            long sizeBytes,
            String sha256,
            String etag) {
    }

    public record AudioAssetSnapshot(
            UUID assetId,
            String audioRole,
            String language,
            String mediaType,
            long sizeBytes,
            String sha256,
            String etag) {
    }
}
