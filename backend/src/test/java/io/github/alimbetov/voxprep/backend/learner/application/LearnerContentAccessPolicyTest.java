package io.github.alimbetov.voxprep.backend.learner.application;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.installation.security.InstallationPrincipal;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
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

    private final CurrentPublicationResolver resolver = mock(CurrentPublicationResolver.class);
    private final ContentRevisionRepository revisions = mock(ContentRevisionRepository.class);
    private final LearnerFrozenAccessResolver frozen = mock(LearnerFrozenAccessResolver.class);
    private final VerifiedLifetimeEntitlementPort entitlements = mock(VerifiedLifetimeEntitlementPort.class);
    private final LearnerContentAccessPolicy policy =
            new LearnerContentAccessPolicy(resolver, revisions, frozen, entitlements);

    @AfterEach
    void resetSecurity() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void publishedFreeContentRequiresNoPurchase() {
        authenticated();
        var ref = published();
        policy.requireAccessible("phrase", "LESSON_01");
        verify(frozen).requiresFull(ref, 1L);
        verifyNoInteractions(entitlements);
    }

    @Test
    void publishedFullContentWithoutVerifiedEntitlementIsDenied() {
        authenticated();
        var ref = published();
        when(frozen.requiresFull(ref, 1L)).thenReturn(true);
        assertThatThrownBy(() -> policy.requireAccessible("phrase", "LESSON_01"))
                .isInstanceOf(LearnerPremiumAccessDeniedException.class);
    }

    @Test
    void independentVerifiedEntitlementAuthorizesFrozenFullContent() {
        authenticated();
        var ref = published();
        when(frozen.requiresFull(ref, 1L)).thenReturn(true);
        when(entitlements.hasVerifiedLifetimeUnlock(INSTALLATION)).thenReturn(true);
        policy.requireAccessible("phrase", "LESSON_01");
        verify(entitlements).hasVerifiedLifetimeUnlock(INSTALLATION);
    }

    @Test
    void missingFrozenMembershipFailsClosed() {
        authenticated();
        var ref = published();
        when(frozen.requiresFull(ref, 1L))
                .thenThrow(new LearnerContentNotFoundException("phrase", "LESSON_01"));
        assertThatThrownBy(() -> policy.requireAccessible("phrase", "LESSON_01"))
                .isInstanceOf(LearnerContentNotFoundException.class);
    }

    @Test
    void missingFrozenSnapshotFailsClosedInsteadOfReadingAuthoringCatalogue() {
        authenticated();
        var ref = published();
        when(frozen.requiresFull(ref, 1L))
                .thenThrow(new LearnerWireSnapshotUnavailableException("immutable catalogue missing"));
        assertThatThrownBy(() -> policy.requireAccessible("phrase", "LESSON_01"))
                .isInstanceOf(LearnerWireSnapshotUnavailableException.class);
    }

    @Test
    void authenticationRequiredEvenForFreeContent() {
        assertThatThrownBy(() -> policy.requireAccessible("phrase", "LESSON_01"))
                .isInstanceOf(AccessDeniedException.class);
        verifyNoInteractions(frozen);
    }

    @Test
    void directQuestionsCannotBypassParentTestAccess() {
        authenticated();
        assertThatThrownBy(() -> policy.requireAccessible("question", "Q_01"))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void absentFromCurrentPublicationIsNotAccessible() {
        authenticated();
        when(resolver.resolve()).thenReturn(new CurrentPublicationSnapshot(
                1, "a".repeat(64), Instant.parse("2026-11-03T12:00:00Z"),
                List.of(ref("OTHER", ContentType.PHRASE))));
        assertThatThrownBy(() -> policy.requireAccessible("phrase", "LESSON_01"))
                .isInstanceOf(LearnerContentNotFoundException.class);
    }

    @Test
    void productionDefaultEntitlementAdapterRemainsFailClosed() {
        org.assertj.core.api.Assertions.assertThat(
                new UnverifiedLifetimeEntitlementAdapter().hasVerifiedLifetimeUnlock(INSTALLATION)).isFalse();
    }

    private void authenticated() {
        SecurityContextHolder.getContext().setAuthentication(
                UsernamePasswordAuthenticationToken.authenticated(
                        new InstallationPrincipal(INSTALLATION), "opaque-token", List.of()));
    }

    private PublicationExactContentRef published() {
        var ref = ref("LESSON_01", ContentType.PHRASE);
        when(resolver.resolve()).thenReturn(new CurrentPublicationSnapshot(
                1, "a".repeat(64), Instant.parse("2026-11-03T12:00:00Z"), List.of(ref)));
        ContentRevisionEntity revision = mock(ContentRevisionEntity.class);
        when(revision.getIdentity()).thenReturn(ref.identity());
        when(revision.getChecksum()).thenReturn(ref.checksum());
        when(revisions.findExact(ref.identity())).thenReturn(Optional.of(revision));
        return ref;
    }

    private static PublicationExactContentRef ref(String code, ContentType type) {
        return new PublicationExactContentRef(
                new ContentRevisionIdentity(new BusinessCode(code), type, new RevisionNumber(1)),
                new Sha256Digest("b".repeat(64)));
    }
}
