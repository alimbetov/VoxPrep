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
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelEntity;
import java.util.List;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import static org.mockito.ArgumentMatchers.any;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsJobEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsJobRepository;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelRepository;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class TtsReviewQueryServiceTest {
    private final TtsJobRepository jobs = mock(TtsJobRepository.class);
    private final LearnerMediaService media = mock(LearnerMediaService.class);
    private final WorkerDeliveryProperties settings = new WorkerDeliveryProperties();
    private final KokoroModelBindingService bindings = mock(KokoroModelBindingService.class);
    private final TtsReviewQueryService review = new TtsReviewQueryService(
            jobs, media, mock(TtsVoiceModelRepository.class),
            new ContentAudioPolicy(), settings, bindings);

    private final UUID revisionId = UUID.randomUUID();
    private final UUID jobId = UUID.randomUUID();

    @Test
    void editorOffersOnlyPiperWhileKokoroPreparationIsDisabled() {
        var catalogue = mock(TtsVoiceModelRepository.class);
        var piper = mock(TtsVoiceModelEntity.class);
        var kokoro = mock(TtsVoiceModelEntity.class);
        var voice = mock(TtsVoiceEntity.class);
        when(voice.getDisplayName()).thenReturn("English Voice");
        when(voice.getLanguage()).thenReturn("en-US");
        when(piper.selectableForNewJobs()).thenReturn(true);
        when(piper.getEngine()).thenReturn(TtsEngine.PIPER);
        when(piper.getCode()).thenReturn("en_US.lessac.medium");
        when(piper.getVoice()).thenReturn(voice);
        when(kokoro.selectableForNewJobs()).thenReturn(true);
        when(kokoro.getEngine()).thenReturn(TtsEngine.KOKORO);
        when(catalogue.findAll(any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(piper, kokoro)));

        var service = new TtsReviewQueryService(jobs, media, catalogue,
                new ContentAudioPolicy(), settings, bindings);
        assertThat(service.availableModels())
                .extracting(TtsReviewQueryService.ModelView::engine)
                .containsExactly("PIPER");
        assertThat(service.availableModels())
                .extracting(TtsReviewQueryService.ModelView::code)
                .containsExactly("en_US.lessac.medium");
    }

    @Test
    void editorHidesKokoroEvenIfItWasMarkedActiveInCatalogue() {
        var catalogue = mock(TtsVoiceModelRepository.class);
        var kokoro = mock(TtsVoiceModelEntity.class);
        when(kokoro.selectableForNewJobs()).thenReturn(true);
        when(kokoro.getEngine()).thenReturn(TtsEngine.KOKORO);
        when(catalogue.findAll(any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(kokoro)));
        var service = new TtsReviewQueryService(jobs, media, catalogue,
                new ContentAudioPolicy(), settings, bindings);
        assertThat(service.availableModels()).isEmpty();
    }

    @Test
    void enabledKokoroAppearsOnlyWhenImmutableBundleBindingExists() {
        var catalogue = mock(TtsVoiceModelRepository.class);
        var model = mock(TtsVoiceModelEntity.class);
        var voice = mock(TtsVoiceEntity.class);
        UUID modelId = UUID.randomUUID();
        when(model.getId()).thenReturn(modelId);
        when(model.selectableForNewJobs()).thenReturn(true);
        when(model.getEngine()).thenReturn(TtsEngine.KOKORO);
        when(model.getCode()).thenReturn("kokoro-af-heart");
        when(model.getVoice()).thenReturn(voice);
        when(voice.getDisplayName()).thenReturn("Kokoro Heart");
        when(voice.getLanguage()).thenReturn("en-US");
        when(catalogue.findAll(any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(model)));
        var service = new TtsReviewQueryService(jobs, media, catalogue,
                new ContentAudioPolicy(), settings, bindings);
        settings.setKokoroEnabled(true);
        assertThat(service.availableModels()).isEmpty();
        when(bindings.find(modelId)).thenReturn(Optional.of(
                new KokoroModelBindingService.Binding(
                        modelId, UUID.randomUUID(), "english-bundle", "a".repeat(64),
                        "af_heart", "voices/af_heart.bin",
                        "b".repeat(64), "phonemizer-pinned",
                        new java.math.BigDecimal("1.000"))));
        assertThat(service.availableModels()).extracting(
                TtsReviewQueryService.ModelView::engine).containsExactly("KOKORO");
    }

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

        assertThat(review.preview(revisionId, jobId).bytes()).containsExactly(new byte[] {1, 2, 3});
        verify(media).read(descriptor);
    }
}
