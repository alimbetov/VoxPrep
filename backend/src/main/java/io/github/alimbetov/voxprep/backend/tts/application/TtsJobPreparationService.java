package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.content.application.ContentRevisionSnapshot;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioRole;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsJobEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsJobRepository;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelRepository;
import java.util.Objects;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TtsJobPreparationService {

    private final ContentRevisionRepository contentRevisionRepository;
    private final TtsVoiceModelRepository voiceModelRepository;
    private final TtsJobRepository ttsJobRepository;
    private final ContentTtsPlanner planner;
    private final JdbcTemplate jdbcTemplate;

    public TtsJobPreparationService(
            ContentRevisionRepository contentRevisionRepository,
            TtsVoiceModelRepository voiceModelRepository,
            TtsJobRepository ttsJobRepository,
            ContentTtsPlanner planner,
            JdbcTemplate jdbcTemplate) {
        this.contentRevisionRepository = contentRevisionRepository;
        this.voiceModelRepository = voiceModelRepository;
        this.ttsJobRepository = ttsJobRepository;
        this.planner = planner;
        this.jdbcTemplate = jdbcTemplate;
    }

    @Transactional
    public PreparationResult prepare(
            UUID contentRevisionId,
            ContentAudioRole role,
            String language,
            String voiceModelCode) {
        Objects.requireNonNull(contentRevisionId, "contentRevisionId");
        Objects.requireNonNull(role, "role");
        Objects.requireNonNull(language, "language");
        String modelCode = required(voiceModelCode, "voiceModelCode");

        var revisionEntity = contentRevisionRepository.findById(contentRevisionId)
                .orElseThrow(() -> new IllegalArgumentException("Content revision not found: " + contentRevisionId));
        var revision = ContentRevisionSnapshot.from(revisionEntity);
        TtsUtterance utterance = planner.plan(revision, language).stream()
                .filter(candidate -> candidate.role() == role)
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException(
                        "TTS role " + role.wireName() + " is not planned for content type "
                                + revision.contentType().wireName()));

        var voiceModel = voiceModelRepository.findByCode(modelCode)
                .orElseThrow(() -> new IllegalArgumentException("TTS voice model not found: " + modelCode));
        if (!voiceModel.selectableForNewJobs()) {
            throw new IllegalStateException("TTS voice model is not selectable for new jobs: " + modelCode);
        }

        String fingerprint = TtsFingerprint.compute(
                contentRevisionId,
                revision.checksumSha256(),
                utterance,
                voiceModel,
                TtsOutputFinalizationService.AUDIO_PROFILE);

        lockFingerprint(fingerprint);

        var existing = ttsJobRepository.findByFingerprint(fingerprint);
        if (existing.isPresent()) {
            TtsJobEntity job = existing.orElseThrow();
            return new PreparationResult(job.getId(), job.getFileId(), fingerprint, true);
        }

        String inputSha256 = TtsFingerprint.sha256(utterance.normalizedText());
        TtsJobEntity job = new TtsJobEntity(voiceModel, utterance.normalizedText(), inputSha256);
        UUID fileId = UUID.randomUUID();
        job.prepareWorkerClaim(
                fileId,
                contentRevisionId,
                role.wireName(),
                utterance.normalizedText(),
                utterance.language(),
                fingerprint);
        TtsJobEntity saved = ttsJobRepository.saveAndFlush(job);
        return new PreparationResult(saved.getId(), fileId, fingerprint, false);
    }

    private void lockFingerprint(String fingerprint) {
        jdbcTemplate.queryForObject(
                "SELECT pg_advisory_xact_lock(hashtextextended(?, 0))",
                Long.class,
                fingerprint);
    }

    private static String required(String value, String field) {
        Objects.requireNonNull(value, field);
        String normalized = value.strip();
        if (normalized.isEmpty()) {
            throw new IllegalArgumentException(field + " must not be blank");
        }
        if (!normalized.equals(value)) {
            throw new IllegalArgumentException(field + " must not contain surrounding whitespace");
        }
        return normalized;
    }

    public record PreparationResult(UUID jobId, UUID fileId, String fingerprint, boolean reused) {
        public PreparationResult {
            Objects.requireNonNull(jobId, "jobId");
            Objects.requireNonNull(fileId, "fileId");
            Objects.requireNonNull(fingerprint, "fingerprint");
        }
    }
}
