package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.asset.application.LearnerMediaService;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsJobStatus;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioPolicy;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelRepository;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsJobEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsJobRepository;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Admin-only read model. Never exposes worker lease, storage keys or credentials. */
@Service
public class TtsReviewQueryService {
    private final TtsJobRepository jobs;
    private final LearnerMediaService media;
    private final TtsVoiceModelRepository voiceModels;
    private final ContentAudioPolicy audioPolicy;

    public TtsReviewQueryService(TtsJobRepository jobs, LearnerMediaService media,
            TtsVoiceModelRepository voiceModels, ContentAudioPolicy audioPolicy) {
        this.jobs = Objects.requireNonNull(jobs);
        this.media = Objects.requireNonNull(media);
        this.voiceModels = Objects.requireNonNull(voiceModels);
        this.audioPolicy = Objects.requireNonNull(audioPolicy);
    }

    @Transactional(readOnly = true)
    public List<JobView> latest(UUID revisionId) {
        return jobs.findByContentRevisionId(Objects.requireNonNull(revisionId),
                PageRequest.of(0, 20, Sort.by(Sort.Direction.DESC, "createdAt")))
                .stream().map(job -> new JobView(job.getId(), job.getStatus().name(),
                        job.getAudioRole(), job.getLanguage(), job.getVoiceModel().getCode(),
                        job.getVoiceModel().getEngine().name(),
                        job.getAttemptCount(), job.getFailureCode(),
                        isPreviewAvailable(job))).toList();
    }

    @Transactional(readOnly = true)
    public List<ModelView> availableModels() {
        return voiceModels.findAll(PageRequest.of(0, 100, Sort.by("code")))
                .stream().filter(model -> model.selectableForNewJobs()
                        && model.getEngine() == TtsEngine.PIPER)
                .map(model -> new ModelView(model.getCode(), model.getVoice().getDisplayName(),
                        model.getVoice().getLanguage(), model.getEngine().name())).toList();
    }

    public List<RoleView> rolesFor(ContentType type) {
        return audioPolicy.rolesFor(type).stream()
                .map(entry -> new RoleView(entry.role().wireName(),
                        entry.role().name().replace('_', ' '))).toList();
    }

    public record ModelView(String code, String displayName, String language, String engine) {}
    public record RoleView(String wireName, String title) {}

    @Transactional(readOnly = true)
    public LearnerMediaService.MediaContent preview(UUID revisionId, UUID jobId) {
        TtsJobEntity job = jobs.findById(Objects.requireNonNull(jobId))
                .orElseThrow(() -> new IllegalArgumentException("TTS job not found"));
        if (!Objects.requireNonNull(revisionId).equals(job.getContentRevisionId())
                || !isPreviewAvailable(job)) {
            throw new IllegalArgumentException("TTS audio preview unavailable for this revision");
        }
        var descriptor = media.describe(job.getOutputAsset().getId());
        if (!"audio/mpeg".equals(descriptor.mediaType())) {
            throw new IllegalStateException("TTS output must be MP3");
        }
        return media.read(descriptor);
    }

    private static boolean isPreviewAvailable(TtsJobEntity job) {
        var asset = job.getOutputAsset();
        return job.getStatus() == TtsJobStatus.READY
                && asset != null
                && asset.getKind() == FileAssetKind.TTS_AUDIO
                && asset.getStatus() == FileAssetStatus.READY
                && "audio/mpeg".equals(asset.getMediaType());
    }

    public record JobView(UUID id, String status, String role, String language,
                          String modelCode, String engine, int attemptCount, String failureCode,
                          boolean previewAvailable) {}
}
