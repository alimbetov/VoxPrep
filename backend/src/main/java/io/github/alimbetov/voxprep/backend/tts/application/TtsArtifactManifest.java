package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;

/**
 * Deterministic immutable descriptor of a pinned inference bundle.
 *
 * This is a value object only: DB persistence and worker delivery are separate
 * K1 tasks. No user-provided URL, executable loader or file path is evaluated.
 */
public record TtsArtifactManifest(
        TtsEngine engine,
        String sourceRevision,
        List<Artifact> artifacts) {

    public TtsArtifactManifest {
        Objects.requireNonNull(engine, "engine");
        sourceRevision = validText(sourceRevision, "sourceRevision", 128);
        Objects.requireNonNull(artifacts, "artifacts");
        if (artifacts.isEmpty() || artifacts.size() > 64) {
            throw new IllegalArgumentException("artifacts count must be between 1 and 64");
        }
        var sorted = new ArrayList<>(artifacts);
        sorted.sort(Comparator.comparing(Artifact::path));
        var unique = new HashSet<String>();
        for (Artifact artifact : sorted) {
            Objects.requireNonNull(artifact, "artifact");
            if (!unique.add(artifact.path())) {
                throw new IllegalArgumentException("duplicate manifest artifact path");
            }
        }
        artifacts = List.copyOf(sorted);
    }

    public String sha256() {
        StringBuilder canonical = new StringBuilder();
        append(canonical, "tts-manifest-v1");
        append(canonical, engine.name());
        append(canonical, sourceRevision);
        for (Artifact artifact : artifacts) {
            append(canonical, artifact.path());
            append(canonical, artifact.role());
            append(canonical, artifact.sha256());
            append(canonical, Long.toString(artifact.sizeBytes()));
            append(canonical, artifact.mediaType());
        }
        return TtsFingerprint.sha256(canonical.toString());
    }

    static void append(StringBuilder output, String value) {
        byte[] encoded = value.getBytes(StandardCharsets.UTF_8);
        output.append(encoded.length).append(':').append(value);
    }

    public record Artifact(
            String path,
            String role,
            String sha256,
            long sizeBytes,
            String mediaType) {
        public Artifact {
            path = validPath(path);
            role = validText(role, "role", 64);
            sha256 = validText(sha256, "sha256", 64);
            if (!sha256.matches("[0-9a-f]{64}")) {
                throw new IllegalArgumentException("invalid artifact sha256");
            }
            if (sizeBytes <= 0 || sizeBytes > 2L * 1024 * 1024 * 1024) {
                throw new IllegalArgumentException("invalid artifact size");
            }
            mediaType = validText(mediaType, "mediaType", 128);
        }
    }

    private static String validPath(String path) {
        path = validText(path, "path", 256);
        if (path.startsWith("/") || path.startsWith(".") || path.endsWith("/")
                || path.contains("\\") || path.contains("//") || path.contains(":")
                || path.contains("\u0000") || !path.matches("[a-zA-Z0-9_./-]+")) {
            throw new IllegalArgumentException("unsafe manifest path");
        }
        for (String component : path.split("/")) {
            if (component.isBlank() || component.equals(".") || component.equals("..")) {
                throw new IllegalArgumentException("unsafe manifest path");
            }
        }
        return path;
    }

    private static String validText(String value, String name, int maxLength) {
        Objects.requireNonNull(value, name);
        if (value.isBlank() || !value.equals(value.strip()) || value.length() > maxLength) {
            throw new IllegalArgumentException("invalid " + name);
        }
        return value;
    }
}
