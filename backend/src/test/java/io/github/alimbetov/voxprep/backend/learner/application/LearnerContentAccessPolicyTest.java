package io.github.alimbetov.voxprep.backend.learner.application;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CollectionAccessLevel;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.CollectionContentMemberEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.CollectionContentMemberRepository;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningCollectionEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningGoalEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningTrackEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.VerticalEntity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.installation.security.InstallationPrincipal;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

class LearnerContentAccessPolicyTest {

    private static final UUID INSTALLATION = UUID.fromString("11111111-1111-4111-8111-111111111111");
    private static final UUID REVISION = UUID.fromString("22222222-2222-4222-8222-222222222222");

    private final CurrentPublicationResolver resolver = mock(CurrentPublicationResolver.class);
    private final ContentRevisionRepository revisions = mock(ContentRevisionRepository.class);
    private final CollectionContentMemberRepository members = mock(CollectionContentMemberRepository.class);
    private final VerifiedLifetimeEntitlementPort entitlements = mock(VerifiedLifetimeEntitlementPort.class);
    private final LearnerContentAccessPolicy policy =
            new LearnerContentAccessPolicy(resolver, revisions, members, entitlements);

    @AfterEach
    void resetSecurity() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void exactPublishedFreeCollectionIsAccessibleWithoutPurchase() {
        authenticated();
        published();
        var free = member(CollectionAccessLevel.FREE);
        when(members.findAllByContentRevision_Id(REVISION)).thenReturn(List.of(free));

        policy.requireAccessible("phrase", "LESSON_01");

        verify(entitlements, never()).hasVerifiedLifetimeUnlock(INSTALLATION);
    }

    @Test
    void fullCollectionCannotBeReadWithoutVerifiedPurchase() {
        authenticated();
        published();
        var full = member(CollectionAccessLevel.FULL);
        when(members.findAllByContentRevision_Id(REVISION)).thenReturn(List.of(full));

        assertThatThrownBy(() -> policy.requireAccessible("phrase", "LESSON_01"))
                .isInstanceOf(LearnerPremiumAccessDeniedException.class);
    }

    @Test
    void independentlyVerifiedFullUnlockAuthorizesFullCollection() {
        authenticated();
        published();
        var full = member(CollectionAccessLevel.FULL);
        when(members.findAllByContentRevision_Id(REVISION)).thenReturn(List.of(full));
        when(entitlements.hasVerifiedLifetimeUnlock(INSTALLATION)).thenReturn(true);

        policy.requireAccessible("phrase", "LESSON_01");

        verify(entitlements).hasVerifiedLifetimeUnlock(INSTALLATION);
    }

    @Test
    void mixedFreeAndFullMembershipRequiresFullUnlock() {
        authenticated();
        published();
        var free = member(CollectionAccessLevel.FREE);
        var full = member(CollectionAccessLevel.FULL);
        when(members.findAllByContentRevision_Id(REVISION)).thenReturn(List.of(free, full));

        assertThatThrownBy(() -> policy.requireAccessible("phrase", "LESSON_01"))
                .isInstanceOf(LearnerPremiumAccessDeniedException.class);
    }

    @Test
    void missingCollectionMembershipFailsClosed() {
        authenticated();
        published();
        when(members.findAllByContentRevision_Id(REVISION)).thenReturn(List.of());

        assertThatThrownBy(() -> policy.requireAccessible("phrase", "LESSON_01"))
                .isInstanceOf(LearnerContentNotFoundException.class);
    }

    @Test
    void authenticationIsRequiredEvenForFreeContent() {
        assertThatThrownBy(() -> policy.requireAccessible("phrase", "LESSON_01"))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void inactiveCollectionCannotAuthorizeFreeContent() {
        authenticated();
        published();
        var member = member(CollectionAccessLevel.FREE);
        when(member.getCollection().getAvailability()).thenReturn(AvailabilityStatus.INACTIVE);
        when(members.findAllByContentRevision_Id(REVISION)).thenReturn(List.of(member));

        assertThatThrownBy(() -> policy.requireAccessible("phrase", "LESSON_01"))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void absentFromCurrentPublicationIsNotAccessible() {
        authenticated();
        when(resolver.resolve()).thenReturn(new CurrentPublicationSnapshot(
                1, "a".repeat(64), Instant.parse("2026-11-03T12:00:00Z"), List.of(
                ref("OTHER", ContentType.PHRASE))));

        assertThatThrownBy(() -> policy.requireAccessible("phrase", "LESSON_01"))
                .isInstanceOf(LearnerContentNotFoundException.class);
    }

    @Test
    void productionDefaultEntitlementAdapterIsFailClosed() {
        org.assertj.core.api.Assertions.assertThat(
                new UnverifiedLifetimeEntitlementAdapter().hasVerifiedLifetimeUnlock(INSTALLATION)).isFalse();
    }

    private void authenticated() {
        SecurityContextHolder.getContext().setAuthentication(
                UsernamePasswordAuthenticationToken.authenticated(
                        new InstallationPrincipal(INSTALLATION), "opaque-token", List.of()));
    }

    private void published() {
        var ref = ref("LESSON_01", ContentType.PHRASE);
        when(resolver.resolve()).thenReturn(new CurrentPublicationSnapshot(
                1, "a".repeat(64), Instant.parse("2026-11-03T12:00:00Z"), List.of(ref)));
        ContentRevisionEntity revision = mock(ContentRevisionEntity.class);
        when(revision.getId()).thenReturn(REVISION);
        when(revision.getIdentity()).thenReturn(ref.identity());
        when(revision.getChecksum()).thenReturn(ref.checksum());
        when(revisions.findExact(ref.identity())).thenReturn(Optional.of(revision));
    }

    private static PublicationExactContentRef ref(String code, ContentType type) {
        return new PublicationExactContentRef(
                new ContentRevisionIdentity(new BusinessCode(code), type, new RevisionNumber(1)),
                new Sha256Digest("b".repeat(64)));
    }

    private CollectionContentMemberEntity member(CollectionAccessLevel level) {
        var member = mock(CollectionContentMemberEntity.class);
        var collection = mock(LearningCollectionEntity.class);
        var track = mock(LearningTrackEntity.class);
        var goal = mock(LearningGoalEntity.class);
        var vertical = mock(VerticalEntity.class);
        when(member.getCollection()).thenReturn(collection);
        when(collection.getTrack()).thenReturn(track);
        when(track.getGoal()).thenReturn(goal);
        when(goal.getVertical()).thenReturn(vertical);
        when(collection.getAvailability()).thenReturn(AvailabilityStatus.ACTIVE);
        when(track.getAvailability()).thenReturn(AvailabilityStatus.ACTIVE);
        when(goal.getAvailability()).thenReturn(AvailabilityStatus.ACTIVE);
        when(vertical.getAvailability()).thenReturn(AvailabilityStatus.ACTIVE);
        when(collection.getAccessLevel()).thenReturn(level);
        return member;
    }
}
