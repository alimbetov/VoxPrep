package io.github.alimbetov.voxprep.backend.tts.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.asset.application.LearnerMediaService;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioPolicy;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsJobStatus;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsJobEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsJobRepository;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelRepository;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class TtsReviewQueryServiceTest {
    private final TtsJobRepository jobs = mock(TtsJobRepository.class);
    private final LearnerMediaService media = mock(LearnerMediaService.class);
    private final TtsReviewQueryService review = new TtsReviewQueryService(
            jobs, media, mock(TtsVoiceModelRepository.class), new ContentAudioPolicy());

    private final UUID revisionId = UUID.randomUUID();
    private final UUID jobId = UUID.randomUUID();

    @Test
    void anotherRevisionCannotPreviewTheSameJob() {
        var job = mock(TtsJobEntity.class);
        when(jobs.findById(jobId)).thenReturn(Optional.of(job));
        when(job.getContentRevisionId()).thenReturn(UUID.randomUUID());

        assertThatThrownBy(() -> review.preview(revisionId, jobId))
                .isInstanceOf(IllegalArgumentException.class);
        verifyNoInteractions(media);
    }

    @Test
    void pendingOrFailedJobsCannotPreviewStorage() {
        var job = mock(TtsJobEntity.class);
        when(jobs.findById(jobId)).thenReturn(Optional.of(job));
        when(job.getContentRevisionId()).thenReturn(revisionId);
        when(job.getStatus()).thenReturn(TtsJobStatus.FAILED);

        assertThatThrownBy(() -> review.preview(revisionId, jobId))
                .isInstanceOf(IllegalArgumentException.class);
        verifyNoInteractions(media);
    }

    @Test
    void readyMp3IsReadOnlyThroughVerifiedMediaService() {
        var job = mock(TtsJobEntity.class);
        var asset = mock(FileAssetEntity.class);
        var assetId = UUID.randomUUID();
        when(jobs.findById(jobId)).thenReturn(Optional.of(job));
        when(job.getContentRevisionId()).thenReturn(revisionId);
        when(job.getStatus()).thenReturn(TtsJobStatus.READY);
        when(job.getOutputAsset()).thenReturn(asset);
        when(asset.getId()).thenReturn(assetId);
        when(asset.getKind()).thenReturn(FileAssetKind.TTS_AUDIO);
        when(asset.getStatus()).thenReturn(FileAssetStatus.READY);
        when(asset.getMediaType()).thenReturn("audio/mpeg");
        var descriptor = new LearnerMediaService.MediaDescriptor(assetId, "private-bucket",
                "tts/key", "audio/mpeg", 3, "a".repeat(64), "\"etag\"");
        when(media.describe(assetId)).thenReturn(descriptor);
        when(media.read(descriptor)).thenReturn(
                new LearnerMediaService.MediaContent("audio/mpeg", new byte[] {1, 2, 3}));

        assertThat(review.preview(revisionId, jobId).bytes()).containsExactly(1, 2, 3);
        verify(media).read(descriptor);
    }
}
