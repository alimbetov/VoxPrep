package io.github.alimbetov.voxprep.backend.learner.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationCandidateStatus;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateManifestRefEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateManifestRefRepository;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCurrentEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCurrentRepository;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationReleaseEntity;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class CurrentPublicationResolverTest {

    private static final String ROOT = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";

    private PublicationCurrentRepository currentRepository;
    private PublicationCandidateManifestRefRepository manifestRepository;
    private CurrentPublicationResolver resolver;

    @BeforeEach
    void setUp() {
        currentRepository = mock(PublicationCurrentRepository.class);
        manifestRepository = mock(PublicationCandidateManifestRefRepository.class);
        resolver = new CurrentPublicationResolver(currentRepository, manifestRepository);
    }

    @Test
    void resolvesOnlyActivePublishedReleaseWithFrozenManifest() {
        UUID candidateId = UUID.randomUUID();
        PublicationCurrentEntity current = mock(PublicationCurrentEntity.class);
        PublicationReleaseEntity release = mock(PublicationReleaseEntity.class);
        PublicationCandidateEntity candidate = mock(PublicationCandidateEntity.class);
        PublicationCandidateManifestRefEntity manifestRef = mock(PublicationCandidateManifestRefEntity.class);
        PublicationExactContentRef ref = new PublicationExactContentRef(
                new ContentRevisionIdentity(
                        new BusinessCode("topic-1"),
                        ContentType.TOPIC,
                        new RevisionNumber(3)),
                new Sha256Digest("bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"));
        Instant publishedAt = Instant.parse("2026-11-03T10:00:00Z");

        when(currentRepository.findById(PublicationCurrentEntity.SINGLETON_ID)).thenReturn(Optional.of(current));
        when(current.getRelease()).thenReturn(release);
        when(release.getCandidate()).thenReturn(candidate);
        when(candidate.getStatus()).thenReturn(PublicationCandidateStatus.PUBLISHED);
        when(candidate.getRootSha256()).thenReturn(ROOT);
        when(candidate.getId()).thenReturn(candidateId);
        when(release.getRootSha256()).thenReturn(ROOT);
        when(release.getContentVersion()).thenReturn(7L);
        when(release.getPublishedAt()).thenReturn(publishedAt);
        when(manifestRepository.findAllByCandidateIdOrderByPositionAsc(candidateId)).thenReturn(List.of(manifestRef));
        when(manifestRef.toExactRef()).thenReturn(ref);

        CurrentPublicationSnapshot snapshot = resolver.resolve();

        assertThat(snapshot.contentVersion()).isEqualTo(7L);
        assertThat(snapshot.rootSha256()).isEqualTo(ROOT);
        assertThat(snapshot.publishedAt()).isEqualTo(publishedAt);
        assertThat(snapshot.refs()).containsExactly(ref);
    }

    @Test
    void failsClosedWhenNoReleaseIsActive() {
        PublicationCurrentEntity current = mock(PublicationCurrentEntity.class);
        when(currentRepository.findById(PublicationCurrentEntity.SINGLETON_ID)).thenReturn(Optional.of(current));
        when(current.getRelease()).thenReturn(null);

        assertThatThrownBy(resolver::resolve)
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("no publication is currently active");
    }

    @Test
    void failsClosedWhenCurrentCandidateIsNotPublished() {
        PublicationCurrentEntity current = mock(PublicationCurrentEntity.class);
        PublicationReleaseEntity release = mock(PublicationReleaseEntity.class);
        PublicationCandidateEntity candidate = mock(PublicationCandidateEntity.class);
        when(currentRepository.findById(PublicationCurrentEntity.SINGLETON_ID)).thenReturn(Optional.of(current));
        when(current.getRelease()).thenReturn(release);
        when(release.getCandidate()).thenReturn(candidate);
        when(candidate.getStatus()).thenReturn(PublicationCandidateStatus.VALIDATED);

        assertThatThrownBy(resolver::resolve)
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("current release candidate is not PUBLISHED");
    }

    @Test
    void failsClosedWhenFrozenManifestIsEmpty() {
        UUID candidateId = UUID.randomUUID();
        PublicationCurrentEntity current = mock(PublicationCurrentEntity.class);
        PublicationReleaseEntity release = mock(PublicationReleaseEntity.class);
        PublicationCandidateEntity candidate = mock(PublicationCandidateEntity.class);
        when(currentRepository.findById(PublicationCurrentEntity.SINGLETON_ID)).thenReturn(Optional.of(current));
        when(current.getRelease()).thenReturn(release);
        when(release.getCandidate()).thenReturn(candidate);
        when(candidate.getStatus()).thenReturn(PublicationCandidateStatus.PUBLISHED);
        when(candidate.getRootSha256()).thenReturn(ROOT);
        when(candidate.getId()).thenReturn(candidateId);
        when(release.getRootSha256()).thenReturn(ROOT);
        when(manifestRepository.findAllByCandidateIdOrderByPositionAsc(candidateId)).thenReturn(List.of());

        assertThatThrownBy(resolver::resolve)
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("current publication manifest is empty");
    }
}
