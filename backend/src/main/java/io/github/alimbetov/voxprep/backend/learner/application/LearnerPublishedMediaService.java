package io.github.alimbetov.voxprep.backend.learner.application;

import io.github.alimbetov.voxprep.backend.asset.application.LearnerMediaService;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsJobStatus;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsJobEntity;
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
    private final TtsJobRepository ttsJobRepository;
    private final LearnerMediaService learnerMediaService;

    public LearnerPublishedMediaService(
            CurrentPublicationResolver currentPublicationResolver,
            ContentRevisionRepository contentRevisionRepository,
            TtsJobRepository ttsJobRepository,
            LearnerMediaService learnerMediaService) {
        this.currentPublicationResolver = Objects.requireNonNull(currentPublicationResolver, "currentPublicationResolver");
        this.contentRevisionRepository = Objects.requireNonNull(contentRevisionRepository, "contentRevisionRepository");
        this.ttsJobRepository = Objects.requireNonNull(ttsJobRepository, "ttsJobRepository");
        this.learnerMediaService = Objects.requireNonNull(learnerMediaService, "learnerMediaService");
    }

    @Transactional(readOnly = true)
    public List<AudioAssetSnapshot> listAudio(String contentTypeWireName, String contentCode) {
        PublishedRevision publishedRevision = requirePublishedRevision(contentTypeWireName, contentCode);
        return ttsJobRepository.findAllByContentRevisionIdAndStatusOrderByAudioRoleAsc(
                        publishedRevision.revision().getId(),
                        TtsJobStatus.READY)
                .stream()
                .map(this::toAudioAsset)
                .toList();
    }

    @Transactional(readOnly = true)
    public LearnerMediaService.MediaDescriptor requireAudio(
            String contentTypeWireName,
            String contentCode,
            UUID assetId) {
        Objects.requireNonNull(assetId, "assetId");
        PublishedRevision publishedRevision = requirePublishedRevision(contentTypeWireName, contentCode);
        TtsJobEntity job = ttsJobRepository.findAllByContentRevisionIdAndStatusOrderByAudioRoleAsc(
                        publishedRevision.revision().getId(),
                        TtsJobStatus.READY)
                .stream()
                .filter(value -> value.getOutputAsset() != null)
                .filter(value -> assetId.equals(value.getOutputAsset().getId()))
                .findFirst()
                .orElseThrow(() -> new LearnerMediaService.MediaUnavailableException("Published audio asset not found"));
        ensureReadyAudio(job.getOutputAsset());
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

    private AudioAssetSnapshot toAudioAsset(TtsJobEntity job) {
        FileAssetEntity asset = job.getOutputAsset();
        if (asset == null) {
            throw new IllegalStateException("READY TTS job has no output asset");
        }
        ensureReadyAudio(asset);
        LearnerMediaService.MediaDescriptor descriptor = learnerMediaService.describe(asset.getId());
        return new AudioAssetSnapshot(
                descriptor.assetId(),
                job.getAudioRole(),
                job.getLanguage(),
                descriptor.mediaType(),
                descriptor.sizeBytes(),
                descriptor.sha256(),
                descriptor.etag());
    }

    private static void ensureReadyAudio(FileAssetEntity asset) {
        if (asset.getKind() != FileAssetKind.TTS_AUDIO || asset.getStatus() != FileAssetStatus.READY) {
            throw new IllegalStateException("published TTS job output is not a READY TTS_AUDIO asset");
        }
    }

    private record PublishedRevision(
            CurrentPublicationSnapshot publication,
            PublicationExactContentRef ref,
            ContentRevisionEntity revision) {
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
