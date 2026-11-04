package io.github.alimbetov.voxprep.backend.learner.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

class LearnerFrozenAccessResolverTest {
    private final LearnerWirePublicationService wire = mock(LearnerWirePublicationService.class);
    private final LearnerFrozenAccessResolver resolver = new LearnerFrozenAccessResolver(wire);

    @Test
    void freeAccessIsDerivedOnlyFromPublishedCatalogue() {
        givenCollection("FREE", true);
        assertThat(resolver.requiresFull(ref(), 7L)).isFalse();
    }

    @Test
    void fullAccessIsDerivedOnlyFromPublishedCatalogue() {
        givenCollection("FULL", true);
        assertThat(resolver.requiresFull(ref(), 7L)).isTrue();
    }

    @Test
    void fullMembershipWinsOverFreeAlias() {
        var free = collection("FREE", true);
        var full = collection("FULL", true);
        when(wire.catalogue("learning-collections", 7)).thenReturn(
                new LearnerWirePublicationService.WireResponse(
                        Map.of("items", List.of(free, full)), "a".repeat(64)));
        assertThat(resolver.requiresFull(ref(), 7L)).isTrue();
    }

    @Test
    void inactiveOrAbsentMembershipCannotGrantFreeAccess() {
        givenCollection("FREE", false);
        assertThatThrownBy(() -> resolver.requiresFull(ref(), 7L))
                .isInstanceOf(LearnerContentNotFoundException.class);
    }

    @Test
    void mismatchedPublishedChecksumCannotGrantAccess() {
        var member = Map.of("type", "CONTENT", "content", Map.of(
                "contentCode", "LESSON_01", "contentType", "phrase",
                "revision", 1, "checksum", "0".repeat(64)));
        when(wire.catalogue("learning-collections", 7)).thenReturn(
                new LearnerWirePublicationService.WireResponse(
                        Map.of("items", List.of(Map.of(
                                "active", true, "accessLevel", "FREE", "members", List.of(member)))),
                        "a".repeat(64)));
        assertThatThrownBy(() -> resolver.requiresFull(ref(), 7L))
                .isInstanceOf(LearnerContentNotFoundException.class);
    }

    @Test
    void malformedAccessLevelAlwaysFailsClosed() {
        givenCollection("UNRECOGNIZED", true);
        assertThatThrownBy(() -> resolver.requiresFull(ref(), 7L))
                .isInstanceOf(LearnerWireSnapshotUnavailableException.class);
    }

    private void givenCollection(String level, boolean active) {
        when(wire.catalogue("learning-collections", 7)).thenReturn(
                new LearnerWirePublicationService.WireResponse(
                        Map.of("items", List.of(collection(level, active))), "a".repeat(64)));
    }

    private static Map<String, Object> collection(String level, boolean active) {
        return Map.of("active", active, "accessLevel", level,
                "members", List.of(Map.of("type", "CONTENT", "content", Map.of(
                        "contentCode", "LESSON_01", "contentType", "phrase",
                        "revision", 1, "checksum", "b".repeat(64)))));
    }

    private static PublicationExactContentRef ref() {
        return new PublicationExactContentRef(
                new ContentRevisionIdentity(new BusinessCode("LESSON_01"),
                        ContentType.PHRASE, new RevisionNumber(1)),
                new Sha256Digest("b".repeat(64)));
    }
}
