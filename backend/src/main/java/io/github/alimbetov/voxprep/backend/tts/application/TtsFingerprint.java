package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelEntity;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;
import java.util.Map;
import java.util.TreeMap;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import java.util.UUID;

public final class TtsFingerprint {

    public static final String VERSION = "tts-fingerprint-v1";
    public static final String VERSION_V2 = "tts-fingerprint-v2";

    private TtsFingerprint() {
    }

    public static String compute(
            UUID contentRevisionId,
            String contentChecksumSha256,
            TtsUtterance utterance,
            TtsVoiceModelEntity voiceModel,
            String audioProfile) {
        Objects.requireNonNull(contentRevisionId, "contentRevisionId");
        Objects.requireNonNull(utterance, "utterance");
        Objects.requireNonNull(voiceModel, "voiceModel");
        String canonical = String.join("\n",
                VERSION,
                contentRevisionId.toString(),
                required(contentChecksumSha256, "contentChecksumSha256"),
                utterance.role().wireName(),
                utterance.normalizedText(),
                utterance.language(),
                utterance.normalizerVersion(),
                required(voiceModel.getCode(), "voiceModelCode"),
                required(voiceModel.getEngineVersion(), "engineVersion"),
                required(voiceModel.getModelVersion(), "modelVersion"),
                required(voiceModel.getModelSha256(), "modelSha256"),
                required(voiceModel.getConfigSha256(), "configSha256"),
                required(audioProfile, "audioProfile"));
        return sha256(canonical);
    }

    /**
     * Kokoro/multi-artifact fingerprint. Existing compute() stays byte-identical
     * for V1 Piper jobs and MUST never be migrated in-place.
     *
     * Synthesis parameters must be normalized by the caller to canonical
     * strings (e.g. speed "1", not "1.0" vs "1.00").
     */
    public static String computeV2(
            UUID contentRevisionId,
            String contentChecksumSha256,
            TtsUtterance utterance,
            TtsEngine engine,
            String engineVersion,
            TtsArtifactManifest manifest,
            String voiceCode,
            String voiceArtifactSha256,
            String phonemizerVersion,
            Map<String, String> parameters,
            String audioProfile) {
        Objects.requireNonNull(contentRevisionId, "contentRevisionId");
        Objects.requireNonNull(utterance, "utterance");
        Objects.requireNonNull(engine, "engine");
        Objects.requireNonNull(manifest, "manifest");
        if (manifest.engine() != engine) {
            throw new IllegalArgumentException("Manifest engine does not match job engine");
        }
        Objects.requireNonNull(parameters, "parameters");
        if (parameters.size() > 32) {
            throw new IllegalArgumentException("Too many synthesis parameters");
        }
        StringBuilder canonical = new StringBuilder();
        for (String item : new String[] {
                VERSION_V2, contentRevisionId.toString(),
                required(contentChecksumSha256, "contentChecksumSha256"),
                utterance.role().wireName(), utterance.normalizedText(),
                utterance.language(), utterance.normalizerVersion(),
                engine.name(), required(engineVersion, "engineVersion"),
                manifest.sha256(), required(voiceCode, "voiceCode"),
                required(voiceArtifactSha256, "voiceArtifactSha256"),
                required(phonemizerVersion, "phonemizerVersion"),
                required(audioProfile, "audioProfile")
        }) {
            TtsArtifactManifest.append(canonical, item);
        }
        for (var entry : new TreeMap<>(parameters).entrySet()) {
            TtsArtifactManifest.append(canonical, required(entry.getKey(), "parameterName"));
            TtsArtifactManifest.append(canonical, required(entry.getValue(), "parameterValue"));
        }
        return sha256(canonical.toString());
    }

    public static String sha256(String value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    private static String required(String value, String field) {
        Objects.requireNonNull(value, field);
        if (value.isBlank()) {
            throw new IllegalArgumentException(field + " must not be blank");
        }
        return value;
    }
}
