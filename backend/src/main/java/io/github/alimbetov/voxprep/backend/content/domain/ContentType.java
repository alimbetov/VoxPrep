package io.github.alimbetov.voxprep.backend.content.domain;

import java.util.Arrays;

public enum ContentType {
    VOCABULARY("vocabulary"),
    INTERVIEW("interview"),
    TOPIC("topic"),
    PHRASE("phrase"),
    SHADOWING("shadowing");

    private final String wireName;

    ContentType(String wireName) {
        this.wireName = wireName;
    }

    public String wireName() {
        return wireName;
    }

    public static ContentType fromWireName(String value) {
        return Arrays.stream(values())
                .filter(type -> type.wireName.equals(value))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unsupported content type: " + value));
    }
}
