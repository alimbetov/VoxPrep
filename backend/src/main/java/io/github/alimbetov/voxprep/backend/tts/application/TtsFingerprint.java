package io.github.alimbetov.voxprep.backend.tts.application;

import io.github.alimbetov.voxprep.backend.tts.persistence.TtsVoiceModelEntity;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;
import java.util.UUID;

public final class TtsFingerprint {

    public static final String VERSION = "tts-fingerprint-v1";

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
