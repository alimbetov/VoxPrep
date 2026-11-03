package io.github.alimbetov.voxprep.backend.tts.domain;

import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import java.util.Objects;

public record ContentAudioPolicyEntry(
        ContentType contentType,
        ContentAudioRole role,
        AudioRequirement requirement) {

    public ContentAudioPolicyEntry {
        Objects.requireNonNull(contentType, "contentType");
        Objects.requireNonNull(role, "role");
        Objects.requireNonNull(requirement, "requirement");
    }
}
