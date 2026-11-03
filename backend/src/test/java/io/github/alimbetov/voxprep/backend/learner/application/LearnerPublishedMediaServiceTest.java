package io.github.alimbetov.voxprep.backend.learner.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.asset.application.LearnerMediaService;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsJobStatus;
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

    private CurrentPublicationResolver currentPublicationResolver;
    private ContentRevisionRepository contentRevisionRepository;
    private TtsJobRepository ttsJobRepository;
    private LearnerMediaService learnerMediaService;
    private LearnerPublishedMediaService service;

    @BeforeEach
    void setUp() {
        currentPublicationResolver = mock(CurrentPublicationResolver.class);
        contentRevisionRepository = mock(ContentRevisionRepository.class);
        ttsJobRepository = mock(TtsJobRepository.class);
        learnerMediaService = mock(LearnerMediaService.class);
        service = new LearnerPublishedMediaService(
                currentPublicationResolver,
                contentRevisionRepository,
                ttsJobRepository,
                learnerMediaService);
    }

    @Test
    void listsOnlyReadyAudioAttachedToExactCurrentPublishedRevision() {
        UUID revisionId = UUID.randomUUID();
        UUID assetId = UUID.randomUUID();
        PublicationExactContentRef ref = ref("topic-1", 2);
        ContentRevisionEntity revision = publishedRevision(ref, revisionId);
        FileAssetEntity asset = readyAudio(assetId);
        TtsJobEntity job = readyJob(asset);

        when(currentPublicationResolver.resolve()).thenReturn(publication(ref));
        when(contentRevisionRepository.findExact(ref.identity())).thenReturn(Optional.of(revision));
        when(ttsJobRepository.findAllByContentRevisionIdAndStatusOrderByAudioRoleAsc(revisionId, TtsJobStatus.READY))
                .thenReturn(List.of(job));
        when(learnerMediaService.describe(assetId)).thenReturn(new LearnerMediaService.MediaDescriptor(
                assetId,
                "voxprep",
                "audio/topic-1.mp3",
                "audio/mpeg",
                123L,
                ASSET_SHA,
                '"' + ASSET_SHA + '"'));

        List<LearnerPublishedMediaService.AudioAssetSnapshot> result = service.listAudio("topic", "topic-1");

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().assetId()).isEqualTo(assetId);
        assertThat(result.getFirst().audioRole()).isEqualTo("primary");
        assertThat(result.getFirst().language()).isEqualTo("en");
        assertThat(result.getFirst().sha256()).isEqualTo(ASSET_SHA);
    }

    @Test
    void refusesAssetIdThatDoesNotBelongToPublishedRevision() {
        UUID revisionId = UUID.randomUUID();
        PublicationExactContentRef ref = ref("topic-1", 2);
        ContentRevisionEntity revision = publishedRevision(ref, revisionId);
        UUID unrelatedAssetId = UUID.randomUUID();

        when(currentPublicationResolver.resolve()).thenReturn(publication(ref));
        when(contentRevisionRepository.findExact(ref.identity())).thenReturn(Optional.of(revision));
        when(ttsJobRepository.findAllByContentRevisionIdAndStatusOrderByAudioRoleAsc(revisionId, TtsJobStatus.READY))
                .thenReturn(List.of());

        assertThatThrownBy(() -> service.requireAudio("topic", "topic-1", unrelatedAssetId))
                .isInstanceOf(LearnerMediaService.MediaUnavailableException.class)
                .hasMessage("Published audio asset not found");
        verify(learnerMediaService, never()).describe(unrelatedAssetId);
    }

    @Test
    void unpublishedContentCannotBeUsedAsMediaAuthority() {
        PublicationExactContentRef ref = ref("other", 1);
        when(currentPublicationResolver.resolve()).thenReturn(publication(ref));

        assertThatThrownBy(() -> service.listAudio("topic", "topic-1"))
                .isInstanceOf(LearnerContentNotFoundException.class)
                .hasMessage("published learner content not found: topic/topic-1");
        verify(ttsJobRepository, never())
                .findAllByContentRevisionIdAndStatusOrderByAudioRoleAsc(org.mockito.ArgumentMatchers.any(),
                        org.mockito.ArgumentMatchers.any());
    }

    @Test
    void failsClosedWhenReadyJobPointsToNonAudioAsset() {
        UUID revisionId = UUID.randomUUID();
        PublicationExactContentRef ref = ref("topic-1", 2);
        ContentRevisionEntity revision = publishedRevision(ref, revisionId);
        FileAssetEntity asset = mock(FileAssetEntity.class);
        TtsJobEntity job = readyJob(asset);
        when(asset.getKind()).thenReturn(FileAssetKind.CONTENT_IMAGE);
        when(asset.getStatus()).thenReturn(FileAssetStatus.READY);

        when(currentPublicationResolver.resolve()).thenReturn(publication(ref));
        when(contentRevisionRepository.findExact(ref.identity())).thenReturn(Optional.of(revision));
        when(ttsJobRepository.findAllByContentRevisionIdAndStatusOrderByAudioRoleAsc(revisionId, TtsJobStatus.READY))
                .thenReturn(List.of(job));

        assertThatThrownBy(() -> service.listAudio("topic", "topic-1"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("published TTS job output is not a READY TTS_AUDIO asset");
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

    private static FileAssetEntity readyAudio(UUID id) {
        FileAssetEntity asset = mock(FileAssetEntity.class);
        when(asset.getId()).thenReturn(id);
        when(asset.getKind()).thenReturn(FileAssetKind.TTS_AUDIO);
        when(asset.getStatus()).thenReturn(FileAssetStatus.READY);
        return asset;
    }

    private static TtsJobEntity readyJob(FileAssetEntity asset) {
        TtsJobEntity job = mock(TtsJobEntity.class);
        when(job.getOutputAsset()).thenReturn(asset);
        when(job.getAudioRole()).thenReturn("primary");
        when(job.getLanguage()).thenReturn("en");
        return job;
    }
}
