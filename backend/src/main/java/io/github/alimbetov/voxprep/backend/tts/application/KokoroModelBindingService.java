package io.github.alimbetov.voxprep.backend.tts.application;

import java.math.BigDecimal;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Binds an approved Kokoro voice model to one immutable STAGED bundle and
 * pinned voice artifact. This catalog operation never enqueues TTS jobs.
 * Existing Piper model records and V1 APIs are not modified.
 */
@Service
public class KokoroModelBindingService {
    private final JdbcTemplate jdbc;

    public KokoroModelBindingService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional
    public Binding bind(
            UUID voiceModelId, UUID bundleId, String voiceCode,
            String phonemizerVersion, BigDecimal speed) {
        Objects.requireNonNull(voiceModelId, "voiceModelId");
        Objects.requireNonNull(bundleId, "bundleId");
        String locale = switch (Objects.requireNonNull(voiceCode, "voiceCode")) {
            case "af_heart", "am_michael" -> "en-US";
            case "bf_emma" -> "en-GB";
            default -> throw new IllegalArgumentException("Unsupported Kokoro voice");
        };
        if (phonemizerVersion == null || phonemizerVersion.isBlank()
                || phonemizerVersion.length() > 128
                || !phonemizerVersion.equals(phonemizerVersion.strip())) {
            throw new IllegalArgumentException("Phonemizer version must be pinned");
        }
        if (speed == null || speed.compareTo(new BigDecimal("0.500")) < 0
                || speed.compareTo(new BigDecimal("2.000")) > 0
                || speed.scale() > 3) {
            throw new IllegalArgumentException("Invalid Kokoro speed");
        }
        String artifact = "voices/" + voiceCode + ".bin";
        // Require a fully pinned and licensed voice-model record, the approved
        // locale, an actual STAGED bundle and the named voice file.
        int inserted = jdbc.update("""
                INSERT INTO app.tts_kokoro_model_binding (
                    voice_model_id, bundle_id, voice_code,
                    voice_artifact_path, phonemizer_version, default_speed)
                SELECT vm.id, b.id, ?, ?, ?, ?
                  FROM app.tts_voice_model vm
                  JOIN app.tts_voice v ON v.id = vm.voice_id
                  CROSS JOIN app.tts_kokoro_bundle b
                  JOIN app.tts_kokoro_bundle_artifact ba
                    ON ba.bundle_id = b.id AND ba.logical_path = ?
                 WHERE vm.id = ? AND vm.engine = 'KOKORO'
                   AND vm.status IN ('APPROVED', 'ACTIVE')
                   AND vm.commercial_use_reviewed = TRUE
                   AND vm.approved_at IS NOT NULL
                   AND vm.license_name IS NOT NULL
                   AND vm.license_reference IS NOT NULL
                   AND v.language = ?
                   AND b.id = ? AND b.status = 'STAGED'
                   AND ba.artifact_role = 'VOICE'
                   AND (
                       SELECT count(*)
                         FROM app.tts_kokoro_bundle_artifact item
                         JOIN app.file_asset asset ON asset.id = item.file_asset_id
                        WHERE item.bundle_id = b.id
                          AND asset.status = 'READY'
                          AND asset.sha256 = item.sha256
                          AND asset.size_bytes = item.size_bytes
                   ) = 4
                   AND (
                       SELECT count(*)
                         FROM app.tts_kokoro_bundle_artifact item
                        WHERE item.bundle_id = b.id
                          AND (
                              (item.logical_path = 'onnx/model_quantized.onnx'
                                  AND item.artifact_role = 'MODEL')
                              OR (item.logical_path IN (
                                  'voices/af_heart.bin', 'voices/am_michael.bin',
                                  'voices/bf_emma.bin') AND item.artifact_role = 'VOICE')
                          )
                   ) = 4
                   AND (
                       SELECT count(*) FROM app.tts_kokoro_bundle_artifact item
                       WHERE item.bundle_id = b.id
                   ) = 4
                """, voiceCode, artifact, phonemizerVersion, speed, artifact,
                voiceModelId, locale, bundleId);
        if (inserted != 1) {
            throw new IllegalStateException("Kokoro model/voice/bundle not eligible for binding");
        }
        return find(voiceModelId).orElseThrow();
    }

    @Transactional(readOnly = true)
    public Optional<Binding> find(UUID voiceModelId) {
        Objects.requireNonNull(voiceModelId, "voiceModelId");
        List<Binding> matches = jdbc.query("""
                SELECT k.voice_model_id, k.bundle_id, b.model_code, b.manifest_sha256,
                       k.voice_code, k.voice_artifact_path, va.sha256,
                       k.phonemizer_version, k.default_speed
                  FROM app.tts_kokoro_model_binding k
                  JOIN app.tts_kokoro_bundle b ON b.id = k.bundle_id
                  JOIN app.tts_kokoro_bundle_artifact va
                    ON va.bundle_id = k.bundle_id
                   AND va.logical_path = k.voice_artifact_path
                 WHERE k.voice_model_id = ? AND b.status = 'STAGED'
                """, (rs, rowNum) -> new Binding(
                        rs.getObject("voice_model_id", UUID.class),
                        rs.getObject("bundle_id", UUID.class),
                        rs.getString("model_code"),
                        rs.getString("manifest_sha256"),
                        rs.getString("voice_code"),
                        rs.getString("voice_artifact_path"),
                        rs.getString("sha256"),
                        rs.getString("phonemizer_version"),
                        rs.getBigDecimal("default_speed")), voiceModelId);
        return matches.stream().findFirst();
    }

    public record Binding(
            UUID voiceModelId, UUID bundleId, String bundleModelCode,
            String manifestSha256, String voiceCode, String voiceArtifactPath,
            String voiceArtifactSha256, String phonemizerVersion,
            BigDecimal speed) { }
}
