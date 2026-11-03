package io.github.alimbetov.voxprep.backend.publication.application;

import io.github.alimbetov.voxprep.backend.asset.domain.ContentAssetRole;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.ContentAssetBindingEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.ContentAssetBindingRepository;
import io.github.alimbetov.voxprep.backend.content.application.ContentRevisionSnapshot;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.tts.application.ContentTtsPlanner;
import io.github.alimbetov.voxprep.backend.tts.application.TtsFingerprint;
import io.github.alimbetov.voxprep.backend.tts.application.TtsOutputFinalizationService;
import io.github.alimbetov.voxprep.backend.tts.domain.AudioRequirement;
import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioPolicy;
import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioPolicyEntry;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsJobStatus;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsJobEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsJobRepository;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
public class JpaPublicationMediaValidator implements PublicationMediaValidator {

    private final ContentRevisionRepository contentRevisionRepository;
    private final ContentAssetBindingRepository bindingRepository;
    private final TtsJobRepository ttsJobRepository;
    private final ContentAudioPolicy audioPolicy;
    private final ContentTtsPlanner planner;

    public JpaPublicationMediaValidator(
            ContentRevisionRepository contentRevisionRepository,
            ContentAssetBindingRepository bindingRepository,
            TtsJobRepository ttsJobRepository,
            ContentAudioPolicy audioPolicy,
            ContentTtsPlanner planner) {
        this.contentRevisionRepository = Objects.requireNonNull(contentRevisionRepository, "contentRevisionRepository");
        this.bindingRepository = Objects.requireNonNull(bindingRepository, "bindingRepository");
        this.ttsJobRepository = Objects.requireNonNull(ttsJobRepository, "ttsJobRepository");
        this.audioPolicy = Objects.requireNonNull(audioPolicy, "audioPolicy");
        this.planner = Objects.requireNonNull(planner, "planner");
    }

    @Override
    @Transactional(readOnly = true)
    public List<PublicationValidationIssue> validate(PublicationExactContentRef ref) {
        Objects.requireNonNull(ref, "ref");
        ContentRevisionEntity revision = contentRevisionRepository.findExact(ref.identity()).orElse(null);
        if (revision == null) {
            return List.of();
        }
        String refKey = ref.identityKey();
        List<PublicationValidationIssue> issues = new ArrayList<>();
        List<ContentAssetBindingEntity> bindings =
                bindingRepository.findAllByContentRevision_IdOrderByRoleAsc(revision.getId());
        Map<ContentAssetRole, ContentAssetBindingEntity> byRole = new EnumMap<>(ContentAssetRole.class);
        for (ContentAssetBindingEntity binding : bindings) {
            byRole.put(binding.getRole(), binding);
            if (binding.getRole().audio()) {
                validateAudioBinding(revision, binding, refKey, issues);
            } else {
                validateImageBinding(binding, refKey, issues);
            }
        }

        for (ContentAudioPolicyEntry policyEntry : audioPolicy.rolesFor(revision.getContentType())) {
            ContentAssetRole assetRole = ContentAssetRole.fromAudioRole(policyEntry.role());
            if (byRole.containsKey(assetRole)) {
                continue;
            }
            if (policyEntry.requirement() == AudioRequirement.REQUIRED) {
                issues.add(new PublicationValidationIssue(
                        PublicationValidationSeverity.ERROR,
                        PublicationValidationCode.MISSING_REQUIRED_AUDIO,
                        refKey,
                        "role=" + policyEntry.role().wireName()));
            } else if (policyEntry.requirement() == AudioRequirement.RECOMMENDED) {
                issues.add(new PublicationValidationIssue(
                        PublicationValidationSeverity.WARNING,
                        PublicationValidationCode.MISSING_RECOMMENDED_AUDIO,
                        refKey,
                        "role=" + policyEntry.role().wireName()));
            }
        }
        return List.copyOf(issues);
    }

    private void validateAudioBinding(
            ContentRevisionEntity revision,
            ContentAssetBindingEntity binding,
            String refKey,
            List<PublicationValidationIssue> issues) {
        var asset = binding.getFileAsset();
        if (asset.getKind() != FileAssetKind.TTS_AUDIO
                || asset.getStatus() != FileAssetStatus.READY
                || !asset.getMediaType().startsWith("audio/")) {
            issues.add(error(
                    PublicationValidationCode.INVALID_AUDIO_BINDING,
                    refKey,
                    "role=" + binding.getRole().wireName() + ", asset=" + asset.getId()));
            return;
        }
        String fingerprint = binding.getSourceFingerprint();
        if (fingerprint == null) {
            issues.add(error(
                    PublicationValidationCode.INVALID_AUDIO_BINDING,
                    refKey,
                    "role=" + binding.getRole().wireName() + " has no source fingerprint"));
            return;
        }
        TtsJobEntity job = ttsJobRepository.findByFingerprint(fingerprint).orElse(null);
        if (job == null
                || job.getStatus() != TtsJobStatus.READY
                || !Objects.equals(job.getContentRevisionId(), revision.getId())
                || !Objects.equals(job.getFileId(), asset.getId())
                || job.getOutputAsset() == null
                || !Objects.equals(job.getOutputAsset().getId(), asset.getId())
                || !Objects.equals(job.getAudioRole(), binding.getRole().wireName())) {
            issues.add(error(
                    PublicationValidationCode.INVALID_AUDIO_BINDING,
                    refKey,
                    "role=" + binding.getRole().wireName() + " is not backed by matching READY TTS job"));
            return;
        }

        try {
            var audioRole = binding.getRole().audioRole().orElseThrow();
            var snapshot = ContentRevisionSnapshot.from(revision);
            var utterance = planner.plan(snapshot, job.getLanguage()).stream()
                    .filter(candidate -> candidate.role() == audioRole)
                    .findFirst()
                    .orElseThrow();
            String expectedFingerprint = TtsFingerprint.compute(
                    revision.getId(),
                    revision.getChecksum().value(),
                    utterance,
                    job.getVoiceModel(),
                    TtsOutputFinalizationService.AUDIO_PROFILE);
            if (!expectedFingerprint.equals(fingerprint)) {
                issues.add(error(
                        PublicationValidationCode.STALE_AUDIO,
                        refKey,
                        "role=" + binding.getRole().wireName()));
            }
        } catch (RuntimeException exception) {
            issues.add(error(
                    PublicationValidationCode.STALE_AUDIO,
                    refKey,
                    "role=" + binding.getRole().wireName() + " cannot be reproduced from current revision"));
        }
    }

    private static void validateImageBinding(
            ContentAssetBindingEntity binding,
            String refKey,
            List<PublicationValidationIssue> issues) {
        var asset = binding.getFileAsset();
        boolean validRoleKind = binding.getRole() == ContentAssetRole.COVER_IMAGE
                ? asset.getKind() == FileAssetKind.COVER_IMAGE
                : binding.getRole() == ContentAssetRole.CONTENT_IMAGE
                        && asset.getKind() == FileAssetKind.CONTENT_IMAGE;
        if (!validRoleKind
                || asset.getStatus() != FileAssetStatus.READY
                || !asset.getMediaType().startsWith("image/")
                || binding.getSourceFingerprint() != null) {
            issues.add(error(
                    PublicationValidationCode.INVALID_IMAGE_BINDING,
                    refKey,
                    "role=" + binding.getRole().wireName() + ", asset=" + asset.getId()));
        }
    }

    private static PublicationValidationIssue error(
            PublicationValidationCode code,
            String refKey,
            String detail) {
        return new PublicationValidationIssue(PublicationValidationSeverity.ERROR, code, refKey, detail);
    }
}
