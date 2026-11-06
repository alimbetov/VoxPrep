package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.content.application.ContentRevisionSnapshot;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioRole;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsJobEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsJobRepository;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelRepository;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Transactionally prepares an immutable Kokoro job and V2 snapshot.
 * No controller invokes this service until V2 output and real inference pass
 * qualification; the existing public TtsJobPreparationService remains Piper-only.
 */
@Service
public class KokoroJobPreparationService {
    private final ContentRevisionRepository revisions;
    private final TtsVoiceModelRepository models;
    private final TtsJobRepository jobs;
    private final ContentTtsPlanner planner;
    private final KokoroModelBindingService bindings;
    private final KokoroManifestCatalog manifests;
    private final KokoroJobSnapshotService snapshots;
    private final JdbcTemplate jdbc;

    public KokoroJobPreparationService(
            ContentRevisionRepository revisions,
            TtsVoiceModelRepository models,
            TtsJobRepository jobs,
            ContentTtsPlanner planner,
            KokoroModelBindingService bindings,
            KokoroManifestCatalog manifests,
            KokoroJobSnapshotService snapshots,
            JdbcTemplate jdbc) {
        this.revisions = revisions;
        this.models = models;
        this.jobs = jobs;
        this.planner = planner;
        this.bindings = bindings;
        this.manifests = manifests;
        this.snapshots = snapshots;
        this.jdbc = jdbc;
    }

    @Transactional
    public TtsJobPreparationService.PreparationResult prepare(
            UUID revisionId, ContentAudioRole role,
            String language, String modelCode) {
        Objects.requireNonNull(revisionId, "revisionId");
        Objects.requireNonNull(role, "role");
        Objects.requireNonNull(language, "language");
        Objects.requireNonNull(modelCode, "modelCode");

        var model = models.findByCode(modelCode)
                .orElseThrow(() -> new IllegalArgumentException("Voice model not found"));
        if (model.getEngine() != TtsEngine.KOKORO || !model.selectableForNewJobs()
                || !model.isCommercialUseReviewed()) {
            throw new IllegalStateException("Kokoro voice model is not approved and active");
        }
        var binding = bindings.find(model.getId())
                .orElseThrow(() -> new IllegalStateException("Kokoro bundle is not pinned"));
        if (!binding.voiceModelId().equals(model.getId())
                || !binding.voiceCode().equals(model.getVoice().getCode())) {
            throw new IllegalStateException("Model/voice binding mismatch");
        }
        String requiredLanguage = binding.voiceCode().equals("bf_emma") ? "en-GB" : "en-US";
        if (!requiredLanguage.equals(language) || !requiredLanguage.equals(model.getVoice().getLanguage())) {
            throw new IllegalArgumentException("Kokoro voice and language mismatch");
        }

        var revision = ContentRevisionSnapshot.from(revisions.findById(revisionId)
                .orElseThrow(() -> new IllegalArgumentException("Content revision not found")));
        var utterance = planner.plan(revision, language).stream()
                .filter(candidate -> candidate.role() == role && candidate.language().equals(language))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("No planned utterance for role/language"));

        var manifest = manifests.verified(binding.bundleId(), binding.manifestSha256());
        String speed = binding.speed().stripTrailingZeros().toPlainString();
        String fingerprint = TtsFingerprint.computeV2(
                revisionId, revision.checksumSha256(), utterance,
                TtsEngine.KOKORO, model.getEngineVersion(), manifest,
                binding.voiceCode(), binding.voiceArtifactSha256(),
                binding.phonemizerVersion(), Map.of("speed", speed),
                TtsOutputFinalizationService.AUDIO_PROFILE);

        jdbc.execute((ConnectionCallback<Void>) connection -> {
            try (var statement = connection.prepareStatement(
                    "SELECT pg_advisory_xact_lock(hashtextextended(?, 0))")) {
                statement.setString(1, fingerprint);
                statement.execute();
            }
            return null;
        });
        var existing = jobs.findByFingerprint(fingerprint);
        if (existing.isPresent()) {
            var job = existing.orElseThrow();
            var pinned = snapshots.find(job.getId())
                    .orElseThrow(() -> new IllegalStateException("Existing Kokoro job has no V2 snapshot"));
            if (!pinned.manifestSha256().equals(binding.manifestSha256())
                    || !pinned.voiceCode().equals(binding.voiceCode())
                    || !pinned.fingerprint().equals(fingerprint)) {
                throw new IllegalStateException("Kokoro fingerprint collision/snapshot mismatch");
            }
            return new TtsJobPreparationService.PreparationResult(
                    job.getId(), job.getFileId(), fingerprint, true);
        }
        var job = new TtsJobEntity(model, utterance.normalizedText(),
                TtsFingerprint.sha256(utterance.normalizedText()));
        UUID fileId = UUID.randomUUID();
        job.prepareWorkerClaim(fileId, revisionId, role.wireName(),
                utterance.normalizedText(), utterance.language(), fingerprint);
        var saved = jobs.saveAndFlush(job);
        snapshots.attach(saved.getId(), model.getId(), binding,
                model.getEngineVersion(), fingerprint);
        return new TtsJobPreparationService.PreparationResult(
                saved.getId(), fileId, fingerprint, false);
    }
}
