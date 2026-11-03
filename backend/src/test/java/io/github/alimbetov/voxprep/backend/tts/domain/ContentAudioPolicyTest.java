package io.github.alimbetov.voxprep.backend.tts.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import java.util.Map;
import java.util.Set;
import org.junit.jupiter.api.Test;

class ContentAudioPolicyTest {

    private final ContentAudioPolicy policy = new ContentAudioPolicy();

    @Test
    void exposesExactSupportedRolesAndRequirements() {
        assertThat(policy.rolesFor(ContentType.VOCABULARY))
                .containsExactly(new ContentAudioPolicyEntry(
                        ContentType.VOCABULARY,
                        ContentAudioRole.PRONUNCIATION,
                        AudioRequirement.OPTIONAL));
        assertThat(policy.rolesFor(ContentType.PHRASE))
                .containsExactly(new ContentAudioPolicyEntry(
                        ContentType.PHRASE,
                        ContentAudioRole.PRONUNCIATION,
                        AudioRequirement.RECOMMENDED));
        assertThat(policy.rolesFor(ContentType.INTERVIEW))
                .containsExactly(
                        new ContentAudioPolicyEntry(
                                ContentType.INTERVIEW,
                                ContentAudioRole.QUESTION,
                                AudioRequirement.RECOMMENDED),
                        new ContentAudioPolicyEntry(
                                ContentType.INTERVIEW,
                                ContentAudioRole.SAMPLE_ANSWER,
                                AudioRequirement.RECOMMENDED));
        assertThat(policy.rolesFor(ContentType.TOPIC))
                .containsExactly(new ContentAudioPolicyEntry(
                        ContentType.TOPIC,
                        ContentAudioRole.NARRATION,
                        AudioRequirement.OPTIONAL));
        assertThat(policy.rolesFor(ContentType.SHADOWING))
                .containsExactly(new ContentAudioPolicyEntry(
                        ContentType.SHADOWING,
                        ContentAudioRole.SHADOWING,
                        AudioRequirement.REQUIRED));
        assertThat(policy.rolesFor(ContentType.QUESTION)).isEmpty();
        assertThat(policy.rolesFor(ContentType.PRACTICE_TEST)).isEmpty();
    }

    @Test
    void qualifiesCompleteContentTypeRoleMatrixFailClosed() {
        Map<ContentType, Set<ContentAudioRole>> allowed = Map.of(
                ContentType.VOCABULARY, Set.of(ContentAudioRole.PRONUNCIATION),
                ContentType.PHRASE, Set.of(ContentAudioRole.PRONUNCIATION),
                ContentType.INTERVIEW, Set.of(ContentAudioRole.QUESTION, ContentAudioRole.SAMPLE_ANSWER),
                ContentType.TOPIC, Set.of(ContentAudioRole.NARRATION),
                ContentType.SHADOWING, Set.of(ContentAudioRole.SHADOWING),
                ContentType.QUESTION, Set.of(),
                ContentType.PRACTICE_TEST, Set.of());

        for (ContentType contentType : ContentType.values()) {
            for (ContentAudioRole role : ContentAudioRole.values()) {
                boolean expectedAllowed = allowed.get(contentType).contains(role);
                assertThat(policy.isAllowed(contentType, role))
                        .as("%s + %s", contentType, role)
                        .isEqualTo(expectedAllowed);

                if (expectedAllowed) {
                    assertThat(policy.requireAllowed(contentType, role).role()).isEqualTo(role);
                } else {
                    assertThatThrownBy(() -> policy.requireAllowed(contentType, role))
                            .isInstanceOf(IllegalArgumentException.class)
                            .hasMessageContaining(contentType.wireName())
                            .hasMessageContaining(role.wireName());
                }
            }
        }
    }

    @Test
    void parsesOnlyNormativeWireRoles() {
        for (ContentAudioRole role : ContentAudioRole.values()) {
            assertThat(ContentAudioRole.fromWireName(role.wireName())).isEqualTo(role);
        }

        assertThatThrownBy(() -> ContentAudioRole.fromWireName("PRIMARY"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Unsupported content audio role");
    }
}
