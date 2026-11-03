package io.github.alimbetov.voxprep.backend.tts.domain;

import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

public final class ContentAudioPolicy {

    private final Map<ContentType, List<ContentAudioPolicyEntry>> entries;

    public ContentAudioPolicy() {
        EnumMap<ContentType, List<ContentAudioPolicyEntry>> configured = new EnumMap<>(ContentType.class);
        configured.put(ContentType.VOCABULARY, List.of(
                entry(ContentType.VOCABULARY, ContentAudioRole.PRONUNCIATION, AudioRequirement.OPTIONAL)));
        configured.put(ContentType.PHRASE, List.of(
                entry(ContentType.PHRASE, ContentAudioRole.PRONUNCIATION, AudioRequirement.RECOMMENDED)));
        configured.put(ContentType.INTERVIEW, List.of(
                entry(ContentType.INTERVIEW, ContentAudioRole.QUESTION, AudioRequirement.RECOMMENDED),
                entry(ContentType.INTERVIEW, ContentAudioRole.SAMPLE_ANSWER, AudioRequirement.RECOMMENDED)));
        configured.put(ContentType.TOPIC, List.of(
                entry(ContentType.TOPIC, ContentAudioRole.NARRATION, AudioRequirement.OPTIONAL)));
        configured.put(ContentType.SHADOWING, List.of(
                entry(ContentType.SHADOWING, ContentAudioRole.SHADOWING, AudioRequirement.REQUIRED)));
        configured.put(ContentType.QUESTION, List.of());
        configured.put(ContentType.PRACTICE_TEST, List.of());
        this.entries = Map.copyOf(configured);
    }

    public List<ContentAudioPolicyEntry> rolesFor(ContentType contentType) {
        Objects.requireNonNull(contentType, "contentType");
        return entries.getOrDefault(contentType, List.of());
    }

    public boolean isAllowed(ContentType contentType, ContentAudioRole role) {
        Objects.requireNonNull(role, "role");
        return rolesFor(contentType).stream().anyMatch(entry -> entry.role() == role);
    }

    public ContentAudioPolicyEntry requireAllowed(ContentType contentType, ContentAudioRole role) {
        Objects.requireNonNull(role, "role");
        return rolesFor(contentType).stream()
                .filter(entry -> entry.role() == role)
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException(
                        "Unsupported content audio role " + role.wireName() + " for content type "
                                + contentType.wireName()));
    }

    private static ContentAudioPolicyEntry entry(
            ContentType contentType,
            ContentAudioRole role,
            AudioRequirement requirement) {
        return new ContentAudioPolicyEntry(contentType, role, requirement);
    }
}
