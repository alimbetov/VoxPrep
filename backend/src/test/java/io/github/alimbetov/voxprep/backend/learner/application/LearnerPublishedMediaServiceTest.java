package io.github.alimbetov.voxprep.backend.learner.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.asset.application.LearnerMediaService;
import io.github.alimbetov.voxprep.backend.asset.domain.ContentAssetRole;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.ContentAssetBindingEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.ContentAssetBindingRepository;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsJobEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsJobRepository;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class LearnerPublishedMediaServiceTest {

    private static final String ROOT = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    private static final String CHECKSUM = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";
    private static final String ASSET_SHA = "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc";
    private static final String FINGERPRINT = "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd";

    private CurrentPublicationResolver currentPublicationResolver;
    private ContentRevisionRepository contentRevisionRepository;
    private ContentAssetBindingRepository bindingRepository;
    private TtsJobRepository ttsJobRepository;
    private LearnerMediaService learnerMediaService;
    private LearnerPublishedMediaService service;

    @BeforeEach
    void setUp() {
        currentPublicationResolver = mock(CurrentPublicationResolver.class);
        contentRevisionRepository = mock(ContentRevisionRepository.class);
        bindingRepository = mock(ContentAssetBindingRepository.class);
        ttsJobRepository = mock(TtsJobRepository.class);
        learnerMediaService = mock(LearnerMediaService.class);
        service = new LearnerPublishedMediaService(
                currentPublicationResolver,
                contentRevisionRepository,
                bindingRepository,
                ttsJobRepository,
                learnerMediaService);
    }

    @Test
    void listsAudioAndImagesOnlyFromExactCurrentPublishedBindings() {
        UUID revisionId = UUID.randomUUID();
        UUID audioId = UUID.randomUUID();
        UUID imageId = UUID.randomUUID();
        PublicationExactContentRef ref = ref("topic-1", 2);
        ContentRevisionEntity revision = publishedRevision(ref, revisionId);
        ContentAssetBindingEntity audio = binding(
                ContentAssetRole.NARRATION,
                readyAsset(audioId, FileAssetKind.TTS_AUDIO, "audio/mpeg"),
                FINGERPRINT);
        ContentAssetBindingEntity image = binding(
                ContentAssetRole.COVER_IMAGE,
                readyAsset(imageId, FileAssetKind.COVER_IMAGE, "image/webp"),
                null);

        when(currentPublicationResolver.resolve()).thenReturn(publication(ref));
        when(contentRevisionRepository.findExact(ref.identity())).thenReturn(Optional.of(revision));
        when(bindingRepository.findAllByContentRevision_IdOrderByRoleAsc(revisionId))
                .thenReturn(List.of(image, audio));
        when(learnerMediaService.describe(audioId)).thenReturn(descriptor(audioId, "audio/mpeg", 123L));
        when(learnerMediaService.describe(imageId)).thenReturn(descriptor(imageId, "image/webp", 456L));
        TtsJobEntity ttsJob = mock(TtsJobEntity.class);
        when(ttsJob.getLanguage()).thenReturn("en-US");
        when(ttsJobRepository.findByFingerprint(FINGERPRINT)).thenReturn(Optional.of(ttsJob));

        var media = service.listMedia("topic", "topic-1");
        var audioOnly = service.listAudio("topic", "topic-1");

        assertThat(media).extracting(LearnerPublishedMediaService.MediaAssetSnapshot::role)
                .containsExactly("coverImage", "narration");
        assertThat(media).extracting(LearnerPublishedMediaService.MediaAssetSnapshot::kind)
                .containsExactly("COVER_IMAGE", "TTS_AUDIO");
        assertThat(audioOnly).hasSize(1);
        assertThat(audioOnly.getFirst().assetId()).isEqualTo(audioId);
        assertThat(audioOnly.getFirst().audioRole()).isEqualTo("narration");
        assertThat(audioOnly.getFirst().language()).isEqualTo("en-US");
    }

    @Test
    void arbitraryAssetIdIsRejectedUnlessBoundToExactPublishedRevision() {
        UUID revisionId = UUID.randomUUID();
        PublicationExactContentRef ref = ref("topic-1", 2);
        ContentRevisionEntity revision = publishedRevision(ref, revisionId);
        UUID unrelatedAssetId = UUID.randomUUID();

        when(currentPublicationResolver.resolve()).thenReturn(publication(ref));
        when(contentRevisionRepository.findExact(ref.identity())).thenReturn(Optional.of(revision));
        when(bindingRepository.findAllByContentRevision_IdOrderByRoleAsc(revisionId)).thenReturn(List.of());

        assertThatThrownBy(() -> service.requireMedia("topic", "topic-1", unrelatedAssetId))
                .isInstanceOf(LearnerMediaService.MediaUnavailableException.class)
                .hasMessage("Published media asset not found");
        verify(learnerMediaService, never()).describe(unrelatedAssetId);
    }

    @Test
    void audioCompatibilityEndpointCannotReadImageBinding() {
        UUID revisionId = UUID.randomUUID();
        UUID imageId = UUID.randomUUID();
        PublicationExactContentRef ref = ref("topic-1", 2);
        ContentRevisionEntity revision = publishedRevision(ref, revisionId);
        ContentAssetBindingEntity image = binding(
                ContentAssetRole.COVER_IMAGE,
                readyAsset(imageId, FileAssetKind.COVER_IMAGE, "image/png"),
                null);

        when(currentPublicationResolver.resolve()).thenReturn(publication(ref));
        when(contentRevisionRepository.findExact(ref.identity())).thenReturn(Optional.of(revision));
        when(bindingRepository.findAllByContentRevision_IdOrderByRoleAsc(revisionId)).thenReturn(List.of(image));

        assertThatThrownBy(() -> service.requireAudio("topic", "topic-1", imageId))
                .isInstanceOf(LearnerMediaService.MediaUnavailableException.class)
                .hasMessage("Published audio asset not found");
    }

    @Test
    void unpublishedContentCannotBeUsedAsMediaAuthority() {
        PublicationExactContentRef ref = ref("other", 1);
        when(currentPublicationResolver.resolve()).thenReturn(publication(ref));

        assertThatThrownBy(() -> service.listMedia("topic", "topic-1"))
                .isInstanceOf(LearnerContentNotFoundException.class)
                .hasMessage("published learner content not found: topic/topic-1");
        verify(bindingRepository, never())
                .findAllByContentRevision_IdOrderByRoleAsc(org.mockito.ArgumentMatchers.any());
    }

    @Test
    void failsClosedWhenBindingKindDoesNotMatchRole() {
        UUID revisionId = UUID.randomUUID();
        UUID assetId = UUID.randomUUID();
        PublicationExactContentRef ref = ref("topic-1", 2);
        ContentRevisionEntity revision = publishedRevision(ref, revisionId);
        ContentAssetBindingEntity invalid = binding(
                ContentAssetRole.NARRATION,
                readyAsset(assetId, FileAssetKind.CONTENT_IMAGE, "image/png"),
                FINGERPRINT);

        when(currentPublicationResolver.resolve()).thenReturn(publication(ref));
        when(contentRevisionRepository.findExact(ref.identity())).thenReturn(Optional.of(revision));
        when(bindingRepository.findAllByContentRevision_IdOrderByRoleAsc(revisionId)).thenReturn(List.of(invalid));

        assertThatThrownBy(() -> service.listMedia("topic", "topic-1"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("published media binding is not deliverable");
    }

    private static PublicationExactContentRef ref(String code, int revision) {
        return new PublicationExactContentRef(
                new ContentRevisionIdentity(
                        new BusinessCode(code),
                        ContentType.TOPIC,
                        new RevisionNumber(revision)),
                new Sha256Digest(CHECKSUM));
    }

    private static CurrentPublicationSnapshot publication(PublicationExactContentRef ref) {
        return new CurrentPublicationSnapshot(
                12L,
                ROOT,
                Instant.parse("2026-11-03T11:00:00Z"),
                List.of(ref));
    }

    private static ContentRevisionEntity publishedRevision(PublicationExactContentRef ref, UUID id) {
        ContentRevisionEntity revision = mock(ContentRevisionEntity.class);
        when(revision.getId()).thenReturn(id);
        when(revision.getIdentity()).thenReturn(ref.identity());
        when(revision.getChecksum()).thenReturn(ref.checksum());
        return revision;
    }

    private static ContentAssetBindingEntity binding(
            ContentAssetRole role,
            FileAssetEntity asset,
            String fingerprint) {
        ContentAssetBindingEntity binding = mock(ContentAssetBindingEntity.class);
        when(binding.getRole()).thenReturn(role);
        when(binding.getFileAsset()).thenReturn(asset);
        when(binding.getSourceFingerprint()).thenReturn(fingerprint);
        return binding;
    }

    private static FileAssetEntity readyAsset(UUID id, FileAssetKind kind, String mediaType) {
        FileAssetEntity asset = mock(FileAssetEntity.class);
        when(asset.getId()).thenReturn(id);
        when(asset.getKind()).thenReturn(kind);
        when(asset.getStatus()).thenReturn(FileAssetStatus.READY);
        when(asset.getMediaType()).thenReturn(mediaType);
        return asset;
    }

    private static LearnerMediaService.MediaDescriptor descriptor(UUID id, String mediaType, long size) {
        return new LearnerMediaService.MediaDescriptor(
                id,
                "voxprep",
                "content/" + id,
                mediaType,
                size,
                ASSET_SHA,
                '"' + ASSET_SHA + '"');
    }
}
