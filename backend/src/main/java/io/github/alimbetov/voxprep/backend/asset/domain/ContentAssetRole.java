package io.github.alimbetov.voxprep.backend.asset.domain;

import io.github.alimbetov.voxprep.backend.tts.domain.ContentAudioRole;
import java.util.Arrays;
import java.util.Optional;

public enum ContentAssetRole {
    COVER_IMAGE("coverImage", FileAssetKind.COVER_IMAGE, null),
    CONTENT_IMAGE("contentImage", FileAssetKind.CONTENT_IMAGE, null),
    PRONUNCIATION("pronunciation", FileAssetKind.TTS_AUDIO, ContentAudioRole.PRONUNCIATION),
    QUESTION("question", FileAssetKind.TTS_AUDIO, ContentAudioRole.QUESTION),
    SAMPLE_ANSWER("sampleAnswer", FileAssetKind.TTS_AUDIO, ContentAudioRole.SAMPLE_ANSWER),
    NARRATION("narration", FileAssetKind.TTS_AUDIO, ContentAudioRole.NARRATION),
    SHADOWING("shadowing", FileAssetKind.TTS_AUDIO, ContentAudioRole.SHADOWING);

    private final String wireName;
    private final FileAssetKind assetKind;
    private final ContentAudioRole audioRole;

    ContentAssetRole(String wireName, FileAssetKind assetKind, ContentAudioRole audioRole) {
        this.wireName = wireName;
        this.assetKind = assetKind;
        this.audioRole = audioRole;
    }

    public String wireName() {
        return wireName;
    }

    public FileAssetKind assetKind() {
        return assetKind;
    }

    public boolean audio() {
        return audioRole != null;
    }

    public Optional<ContentAudioRole> audioRole() {
        return Optional.ofNullable(audioRole);
    }

    public static ContentAssetRole fromWireName(String value) {
        return Arrays.stream(values())
                .filter(role -> role.wireName.equals(value))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unsupported content asset role: " + value));
    }

    public static ContentAssetRole fromAudioRole(ContentAudioRole role) {
        return Arrays.stream(values())
                .filter(candidate -> candidate.audioRole == role)
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unsupported audio asset role: " + role));
    }
}
