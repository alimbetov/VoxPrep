package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioPolicy;
import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioRole;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelRepository;
import java.util.Objects;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Operator command: delegates fingerprint, idempotency and lease preparation to the existing service. */
@Service
public class TtsReviewCommandService {
    private final ContentRevisionRepository revisions;
    private final TtsVoiceModelRepository models;
    private final TtsJobPreparationService preparation;
    private final KokoroJobPreparationService kokoroPreparation;
    private final WorkerDeliveryProperties delivery;
    private final ContentAudioPolicy policy;

    public TtsReviewCommandService(ContentRevisionRepository revisions,
            TtsVoiceModelRepository models, TtsJobPreparationService preparation,
            KokoroJobPreparationService kokoroPreparation, WorkerDeliveryProperties delivery,
            ContentAudioPolicy policy) {
        this.revisions = Objects.requireNonNull(revisions);
        this.models = Objects.requireNonNull(models);
        this.preparation = Objects.requireNonNull(preparation);
        this.kokoroPreparation = Objects.requireNonNull(kokoroPreparation);
        this.delivery = Objects.requireNonNull(delivery);
        this.policy = Objects.requireNonNull(policy);
    }

    @Transactional
    public TtsJobPreparationService.PreparationResult prepare(
            UUID revisionId, String audioRole, String voiceModelCode) {
        var revision = revisions.findById(Objects.requireNonNull(revisionId))
                .orElseThrow(() -> new IllegalArgumentException("Content revision not found"));
        if (revision.getLifecycle() != ContentLifecycleStatus.READY_FOR_AUDIO) {
            throw new IllegalStateException("Only READY_FOR_AUDIO revisions can request synthesis");
        }
        var role = ContentAudioRole.fromWireName(Objects.requireNonNull(audioRole));
        policy.requireAllowed(revision.getContentType(), role);

        if (voiceModelCode == null || voiceModelCode.length() > 128) {
            throw new IllegalArgumentException("Invalid voice model");
        }
        var model = models.findByCode(voiceModelCode)
                .orElseThrow(() -> new IllegalArgumentException("Voice model not found"));
        if (!model.selectableForNewJobs()) {
            throw new IllegalStateException("Voice model is not available for new jobs");
        }
        // Locale is determined by the approved voice, never by arbitrary untrusted browser input.
        if (model.getEngine() == TtsEngine.KOKORO) {
            if (!delivery.isKokoroEnabled()) {
                throw new IllegalStateException("Kokoro worker V2 is disabled");
            }
            return kokoroPreparation.prepare(
                    revisionId, role, model.getVoice().getLanguage(), model.getCode());
        }
        return preparation.prepare(revisionId, role, model.getVoice().getLanguage(), model.getCode());
    }
}
