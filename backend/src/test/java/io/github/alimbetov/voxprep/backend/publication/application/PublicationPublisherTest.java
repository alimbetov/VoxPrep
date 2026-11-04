package io.github.alimbetov.voxprep.backend.publication.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationCandidateStatus;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateManifestRefEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateManifestRefRepository;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateRepository;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCurrentEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCurrentRepository;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationReleaseEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationReleaseRepository;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class PublicationPublisherTest {

    private static final String ROOT = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    private static final Instant PUBLISHED_AT = Instant.parse("2026-11-03T09:30:00Z");

    @Mock private PublicationCandidateRepository candidateRepository;
    @Mock private PublicationCandidateManifestRefRepository manifestRepository;
    @Mock private PublicationReleaseRepository releaseRepository;
    @Mock private PublicationCurrentRepository currentRepository;
    @Mock private PublicationCandidateValidator validator;
    @Mock private PublicationContentVersionAllocator versionAllocator;
    @Mock private PublicationContentFreezer contentFreezer;
    @Mock private PublicationCurrentEntity current;

    private PublicationPublisher publisher;

    @BeforeEach
    void setUp() {
        publisher = new PublicationPublisher(
                candidateRepository,
                manifestRepository,
                releaseRepository,
                currentRepository,
                validator,
                versionAllocator,
                contentFreezer);
    }

    @Test
    void publishesValidatedFrozenManifestAndSwitchesCurrentAtomically() {
        UUID candidateId = UUID.randomUUID();
        PublicationCandidateEntity candidate = validatedCandidate(ROOT);
        PublicationExactContentRef ref = ref("question-1", ContentType.QUESTION, 1, 'b');
        PublicationCandidateManifestRefEntity persisted =
                new PublicationCandidateManifestRefEntity(candidateId, 0, ref);
        PublicationValidationResult validation = new PublicationValidationResult(
                List.of(ref.canonicalKey()), List.of(), ROOT);

        when(candidateRepository.findByIdForUpdate(candidateId)).thenReturn(Optional.of(candidate));
        when(manifestRepository.findAllByCandidateIdOrderByPositionAsc(candidateId)).thenReturn(List.of(persisted));
        when(validator.validate(List.of(ref))).thenReturn(validation);
        when(currentRepository.findByIdForUpdate(PublicationCurrentEntity.SINGLETON_ID))
                .thenReturn(Optional.of(current));
        when(versionAllocator.nextVersion()).thenReturn(42L);
        when(releaseRepository.saveAndFlush(org.mockito.ArgumentMatchers.any(PublicationReleaseEntity.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        PublicationPublishResult result = publisher.publish(candidateId, PUBLISHED_AT);

        assertThat(result.contentVersion()).isEqualTo(42L);
        assertThat(result.rootSha256()).isEqualTo(ROOT);
        assertThat(result.publishedAt()).isEqualTo(PUBLISHED_AT);
        assertThat(result.replayed()).isFalse();
        assertThat(candidate.getStatus()).isEqualTo(PublicationCandidateStatus.PUBLISHED);
        verify(contentFreezer).freeze(List.of(ref), PUBLISHED_AT);
        verify(current).switchTo(org.mockito.ArgumentMatchers.any(PublicationReleaseEntity.class),
                org.mockito.ArgumentMatchers.eq(PUBLISHED_AT));
        verify(currentRepository).save(current);
        verify(candidateRepository).save(candidate);
    }

    @Test
    void replayReturnsExistingReleaseWithoutAllocatingVersionOrMovingCurrent() {
        UUID candidateId = UUID.randomUUID();
        PublicationCandidateEntity candidate = validatedCandidate(ROOT);
        candidate.markPublished();
        PublicationReleaseEntity existing = new PublicationReleaseEntity(candidate, 7L, ROOT, PUBLISHED_AT);

        when(candidateRepository.findByIdForUpdate(candidateId)).thenReturn(Optional.of(candidate));
        when(releaseRepository.findByCandidateId(candidateId)).thenReturn(Optional.of(existing));

        PublicationPublishResult result = publisher.publish(candidateId, PUBLISHED_AT.plusSeconds(60));

        assertThat(result.contentVersion()).isEqualTo(7L);
        assertThat(result.replayed()).isTrue();
        verify(versionAllocator, never()).nextVersion();
        verify(contentFreezer, never()).freeze(org.mockito.ArgumentMatchers.anyList(), org.mockito.ArgumentMatchers.any());
        verify(currentRepository, never()).findByIdForUpdate(PublicationCurrentEntity.SINGLETON_ID);
        verify(releaseRepository, never()).saveAndFlush(org.mockito.ArgumentMatchers.any());
    }

    @Test
    void refusesPublishWhenFrozenManifestRootDiffersFromValidatedCandidate() {
        UUID candidateId = UUID.randomUUID();
        PublicationCandidateEntity candidate = validatedCandidate(ROOT);
        PublicationExactContentRef ref = ref("topic-1", ContentType.TOPIC, 1, 'c');
        PublicationCandidateManifestRefEntity persisted =
                new PublicationCandidateManifestRefEntity(candidateId, 0, ref);
        String otherRoot = "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd";

        when(candidateRepository.findByIdForUpdate(candidateId)).thenReturn(Optional.of(candidate));
        when(manifestRepository.findAllByCandidateIdOrderByPositionAsc(candidateId)).thenReturn(List.of(persisted));
        when(validator.validate(List.of(ref))).thenReturn(new PublicationValidationResult(
                List.of(ref.canonicalKey()), List.of(), otherRoot));

        assertThatThrownBy(() -> publisher.publish(candidateId, PUBLISHED_AT))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("frozen publication manifest root does not match candidate root");

        assertThat(candidate.getStatus()).isEqualTo(PublicationCandidateStatus.VALIDATED);
        verify(contentFreezer, never()).freeze(org.mockito.ArgumentMatchers.anyList(), org.mockito.ArgumentMatchers.any());
        verify(versionAllocator, never()).nextVersion();
        verify(currentRepository, never()).findByIdForUpdate(PublicationCurrentEntity.SINGLETON_ID);
        verify(releaseRepository, never()).saveAndFlush(org.mockito.ArgumentMatchers.any());
    }

    private static PublicationCandidateEntity validatedCandidate(String root) {
        PublicationCandidateEntity candidate = new PublicationCandidateEntity(PublicationCandidateStatus.DRAFT);
        candidate.markValidated(root, Instant.parse("2026-11-03T09:00:00Z"));
        return candidate;
    }

    private static PublicationExactContentRef ref(
            String code, ContentType type, int revision, char checksumDigit) {
        return new PublicationExactContentRef(
                new ContentRevisionIdentity(
                        new BusinessCode(code), type, new RevisionNumber(revision)),
                new Sha256Digest(String.valueOf(checksumDigit).repeat(64)));
    }
}
