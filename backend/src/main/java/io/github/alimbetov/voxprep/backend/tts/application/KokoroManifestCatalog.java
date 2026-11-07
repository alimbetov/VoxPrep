package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Reconstruct the canonical immutable manifest from staged PostgreSQL assets. */
@Service
public class KokoroManifestCatalog {
    private final JdbcTemplate jdbc;

    public KokoroManifestCatalog(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional(readOnly = true)
    public TtsArtifactManifest verified(UUID bundleId, String expectedDigest) {
        Objects.requireNonNull(bundleId, "bundleId");
        var metadata = jdbc.query("""
                SELECT source_revision, manifest_sha256
                  FROM app.tts_kokoro_bundle
                 WHERE id = ? AND status = 'STAGED'
                """, (rs, n) -> new String[] {
                        rs.getString("source_revision"), rs.getString("manifest_sha256")
                }, bundleId);
        if (metadata.size() != 1) {
            throw new IllegalStateException("Missing staged Kokoro bundle");
        }
        List<TtsArtifactManifest.Artifact> artifacts = jdbc.query("""
                SELECT a.logical_path, a.artifact_role, a.sha256,
                       a.size_bytes, a.media_type
                  FROM app.tts_kokoro_bundle_artifact a
                  JOIN app.file_asset fa ON fa.id = a.file_asset_id
                 WHERE a.bundle_id = ?
                   AND fa.kind = 'TTS_MODEL' AND fa.status = 'READY'
                   AND fa.sha256 = a.sha256 AND fa.size_bytes = a.size_bytes
                 ORDER BY a.logical_path
                """, (rs, n) -> new TtsArtifactManifest.Artifact(
                        rs.getString("logical_path"), rs.getString("artifact_role"),
                        rs.getString("sha256"), rs.getLong("size_bytes"),
                        rs.getString("media_type")), bundleId);
        if (artifacts.size() != 4
                || artifacts.stream().noneMatch(a -> a.path().equals("onnx/model_quantized.onnx")
                        && a.role().equals("MODEL"))
                || artifacts.stream().filter(a -> a.role().equals("VOICE")
                        && (a.path().equals("voices/af_heart.bin")
                            || a.path().equals("voices/am_michael.bin")
                            || a.path().equals("voices/bf_emma.bin"))).count() != 3) {
            throw new IllegalStateException("Kokoro bundle must contain ONNX + three READY voice assets");
        }
        var manifest = new TtsArtifactManifest(TtsEngine.KOKORO, metadata.getFirst()[0], artifacts);
        if (!manifest.sha256().equals(metadata.getFirst()[1])
                || !manifest.sha256().equals(expectedDigest)) {
            throw new IllegalStateException("Kokoro manifest checksum mismatch");
        }
        return manifest;
    }
}
