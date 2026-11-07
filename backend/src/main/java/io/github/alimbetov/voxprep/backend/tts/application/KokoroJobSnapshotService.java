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
 * Persisted immutable V2 job model identity. An accepted snapshot must match
 * both the prepared job fingerprint and its approved model/bundle binding.
 * The database trigger independently verifies these invariants on INSERT.
 *
 * This does not enable Kokoro job creation or its V2 claim endpoint.
 */
@Service
public class KokoroJobSnapshotService {
    private final JdbcTemplate jdbc;

    public KokoroJobSnapshotService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional
    public void attach(
            UUID jobId, UUID voiceModelId,
            KokoroModelBindingService.Binding binding,
            String engineVersion, String fingerprint) {
        Objects.requireNonNull(jobId, "jobId");
        Objects.requireNonNull(voiceModelId, "voiceModelId");
        Objects.requireNonNull(binding, "binding");
        if (!voiceModelId.equals(binding.voiceModelId())) {
            throw new IllegalArgumentException("Binding belongs to another voice model");
        }
        if (engineVersion == null || engineVersion.isBlank()
                || engineVersion.length() > 64
                || !engineVersion.equals(engineVersion.strip())) {
            throw new IllegalArgumentException("Invalid engine version");
        }
        if (fingerprint == null || !fingerprint.matches("[0-9a-f]{64}")) {
            throw new IllegalArgumentException("Invalid V2 fingerprint");
        }
        jdbc.update("""
                INSERT INTO app.tts_kokoro_job_snapshot (
                    job_id, voice_model_id, bundle_id, manifest_sha256,
                    voice_code, voice_artifact_sha256, phonemizer_version,
                    engine_version, speed, fingerprint_version, fingerprint)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'tts-fingerprint-v2', ?)
                """, jobId, voiceModelId, binding.bundleId(),
                binding.manifestSha256(), binding.voiceCode(),
                binding.voiceArtifactSha256(), binding.phonemizerVersion(),
                engineVersion, binding.speed(), fingerprint);
    }

    @Transactional(readOnly = true)
    public Optional<Snapshot> find(UUID jobId) {
        Objects.requireNonNull(jobId, "jobId");
        List<Snapshot> rows = jdbc.query("""
                SELECT s.job_id, s.voice_model_id, s.bundle_id,
                       b.model_code AS bundle_model_code, s.manifest_sha256,
                       s.voice_code, s.voice_artifact_sha256,
                       s.phonemizer_version, s.engine_version, s.speed,
                       s.fingerprint_version, s.fingerprint
                  FROM app.tts_kokoro_job_snapshot s
                  JOIN app.tts_kokoro_bundle b ON b.id = s.bundle_id
                 WHERE s.job_id = ? AND b.status = 'STAGED'
                """, (rs, rowNum) -> new Snapshot(
                        rs.getObject("job_id", UUID.class),
                        rs.getObject("voice_model_id", UUID.class),
                        rs.getObject("bundle_id", UUID.class),
                        rs.getString("bundle_model_code"),
                        rs.getString("manifest_sha256"),
                        rs.getString("voice_code"),
                        rs.getString("voice_artifact_sha256"),
                        rs.getString("phonemizer_version"),
                        rs.getString("engine_version"),
                        rs.getBigDecimal("speed"),
                        rs.getString("fingerprint_version"),
                        rs.getString("fingerprint")), jobId);
        return rows.stream().findFirst();
    }

    public record Snapshot(
            UUID jobId, UUID voiceModelId, UUID bundleId, String bundleModelCode,
            String manifestSha256, String voiceCode, String voiceArtifactSha256,
            String phonemizerVersion, String engineVersion, BigDecimal speed,
            String fingerprintVersion, String fingerprint) { }
}
