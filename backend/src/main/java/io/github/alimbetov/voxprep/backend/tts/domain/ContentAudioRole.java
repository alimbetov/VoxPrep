package io.github.alimbetov.voxprep.backend.tts.domain;

import java.util.Arrays;

public enum ContentAudioRole {
    PRONUNCIATION("pronunciation"),
    QUESTION("question"),
    SAMPLE_ANSWER("sampleAnswer"),
    NARRATION("narration"),
    SHADOWING("shadowing");

    private final String wireName;

    ContentAudioRole(String wireName) {
        this.wireName = wireName;
    }

    public String wireName() {
        return wireName;
    }

    public static ContentAudioRole fromWireName(String value) {
        return Arrays.stream(values())
                .filter(role -> role.wireName.equals(value))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unsupported content audio role: " + value));
    }
}
