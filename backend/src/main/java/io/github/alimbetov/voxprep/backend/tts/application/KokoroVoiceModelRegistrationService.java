package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.tts.domain.TtsVoiceModelStatus;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelEntity;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelRepository;
import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceRepository;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Catalog registration of real Kokoro models from a verified staged bundle.
 * NEVER auto-approves a license, activates a voice or enrolls a TTS job.
 */
@Service
public class KokoroVoiceModelRegistrationService {
    private final JdbcTemplate jdbc;
    private final KokoroManifestCatalog manifests;
    private final TtsVoiceRepository voices;
    private final TtsVoiceModelRepository models;

    public KokoroVoiceModelRegistrationService(
            JdbcTemplate jdbc, KokoroManifestCatalog manifests,
            TtsVoiceRepository voices, TtsVoiceModelRepository models) {
        this.jdbc = jdbc;
        this.manifests = manifests;
        this.voices = voices;
        this.models = models;
    }

    @Transactional
    public UUID registerCandidate(UUID bundleId, String voiceCode, String modelCode,
                                  String engineVersion) {
        String[] selected = switch (voiceCode) {
            case "af_heart" -> new String[] {"en-US", "Kokoro Heart", "US", "FEMALE"};
            case "am_michael" -> new String[] {"en-US", "Kokoro Michael", "US", "MALE"};
            case "bf_emma" -> new String[] {"en-GB", "Kokoro Emma", "GB", "FEMALE"};
            default -> throw new IllegalArgumentException("Unsupported Kokoro education voice");
        };
        if (modelCode == null || !modelCode.matches("[a-zA-Z0-9_.-]{1,128}")) {
            throw new IllegalArgumentException("Invalid model code");
        }
        if (engineVersion == null || !engineVersion.matches("[a-zA-Z0-9_.-]{1,64}")) {
            throw new IllegalArgumentException("Engine runtime version must be pinned");
        }
        if (models.findByCode(modelCode).isPresent()) {
            throw new IllegalStateException("Model code already registered");
        }
        var bundles = jdbc.query("""
                SELECT source_repository, source_revision, license_name,
                       license_reference, manifest_sha256
                  FROM app.tts_kokoro_bundle
                 WHERE id = ? AND status = 'STAGED'
                """, (rs, n) -> new String[] {
                    rs.getString("source_repository"), rs.getString("source_revision"),
                    rs.getString("license_name"), rs.getString("license_reference"),
                    rs.getString("manifest_sha256")
                }, bundleId);
        if (bundles.size() != 1) {
            throw new IllegalStateException("Kokoro model bundle is not staged");
        }
        String[] bundle = bundles.getFirst();
        var manifest = manifests.verified(bundleId, bundle[4]);
        if (manifest.artifacts().stream().noneMatch(a ->
                a.path().equals("voices/" + voiceCode + ".bin") && a.role().equals("VOICE"))) {
            throw new IllegalStateException("Selected voice is not in verified bundle");
        }
        // Register disabled until an operator approves the source license and
        // switches the voice/model to enabled/ACTIVE through reviewed workflow.
        var voice = voices.findByCode(voiceCode)
                .orElseGet(() -> voices.saveAndFlush(new TtsVoiceEntity(
                        voiceCode, selected[1], selected[0], selected[2],
                        selected[3], "NEUTRAL", false)));
        if (!selected[0].equals(voice.getLanguage())) {
            throw new IllegalStateException("Existing voice has incompatible locale");
        }
        var model = TtsVoiceModelEntity.forKokoro(
                modelCode, voice, engineVersion, "kokoro-82m-v1",
                bundle[0], bundle[1], TtsVoiceModelStatus.READY_FOR_REVIEW,
                bundle[2], bundle[3], false, null);
        return models.saveAndFlush(model).getId();
    }
}
