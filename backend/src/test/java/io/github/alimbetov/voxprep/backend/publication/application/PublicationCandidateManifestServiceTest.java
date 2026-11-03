package io.github.alimbetov.voxprep.backend.publication.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
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
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class PublicationCandidateManifestServiceTest {

    private static final String ROOT = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";

    @Mock
    private PublicationCandidateRepository candidateRepository;

    @Mock
    private PublicationCandidateManifestRefRepository manifestRepository;

    @Mock
    private PublicationCandidateValidator validator;

    private PublicationCandidateManifestService service;

    @BeforeEach
    void setUp() {
        service = new PublicationCandidateManifestService(candidateRepository, manifestRepository, validator);
    }

    @Test
    void persistsCanonicalManifestBeforeBindingRootToCandidate() {
        UUID candidateId = UUID.randomUUID();
        PublicationCandidateEntity candidate = new PublicationCandidateEntity(PublicationCandidateStatus.DRAFT);
        PublicationExactContentRef question = ref("question-2", ContentType.QUESTION, 2, 'b');
        PublicationExactContentRef vocabulary = ref("vocabulary-1", ContentType.VOCABULARY, 1, 'a');
        List<PublicationExactContentRef> unordered = List.of(question, vocabulary);
        List<PublicationExactContentRef> canonical = unordered.stream().sorted().toList();
        List<String> canonicalKeys = canonical.stream().map(PublicationExactContentRef::canonicalKey).toList();
        PublicationValidationResult validation = new PublicationValidationResult(canonicalKeys, List.of(), ROOT);

        when(candidateRepository.findById(candidateId)).thenReturn(Optional.of(candidate));
        when(manifestRepository.existsByCandidateId(candidateId)).thenReturn(false);
        when(validator.validate(unordered)).thenReturn(validation);

        PublicationValidationResult actual = service.validateAndFreeze(
                candidateId, unordered, Instant.parse("2026-11-03T08:30:00Z"));

        assertThat(actual).isEqualTo(validation);
        assertThat(candidate.getStatus()).isEqualTo(PublicationCandidateStatus.VALIDATED);
        assertThat(candidate.getRootSha256()).isEqualTo(ROOT);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<Iterable<PublicationCandidateManifestRefEntity>> captor =
                ArgumentCaptor.forClass(Iterable.class);
        verify(manifestRepository).saveAll(captor.capture());
        List<PublicationCandidateManifestRefEntity> persisted = new ArrayList<>();
        captor.getValue().forEach(persisted::add);
        assertThat(persisted).hasSize(2);
        assertThat(persisted.get(0).getPosition()).isZero();
        assertThat(persisted.get(0).toExactRef()).isEqualTo(canonical.get(0));
        assertThat(persisted.get(1).getPosition()).isEqualTo(1);
        assertThat(persisted.get(1).toExactRef()).isEqualTo(canonical.get(1));
        verify(manifestRepository).flush();
        verify(candidateRepository).save(candidate);
    }

    @Test
    void invalidValidationNeverPersistsOrValidatesCandidate() {
        UUID candidateId = UUID.randomUUID();
        PublicationCandidateEntity candidate = new PublicationCandidateEntity(PublicationCandidateStatus.DRAFT);
        List<PublicationExactContentRef> refs = List.of(ref("draft", ContentType.TOPIC, 1, 'c'));
        PublicationValidationIssue issue = new PublicationValidationIssue(
                PublicationValidationCode.NOT_PUBLISHABLE, "draft:topic:1", "lifecycle=DRAFT");
        PublicationValidationResult validation = new PublicationValidationResult(
                refs.stream().sorted().map(PublicationExactContentRef::canonicalKey).toList(),
                List.of(issue),
                null);

        when(candidateRepository.findById(candidateId)).thenReturn(Optional.of(candidate));
        when(manifestRepository.existsByCandidateId(candidateId)).thenReturn(false);
        when(validator.validate(refs)).thenReturn(validation);

        assertThat(service.validateAndFreeze(candidateId, refs, Instant.parse("2026-11-03T08:30:00Z")))
                .isEqualTo(validation);
        assertThat(candidate.getStatus()).isEqualTo(PublicationCandidateStatus.DRAFT);
        assertThat(candidate.getRootSha256()).isNull();
        verify(manifestRepository, never()).saveAll(any());
        verify(candidateRepository, never()).save(any());
    }

    private static PublicationExactContentRef ref(
            String code, ContentType type, int revision, char checksumDigit) {
        return new PublicationExactContentRef(
                new ContentRevisionIdentity(
                        new BusinessCode(code), type, new RevisionNumber(revision)),
                new Sha256Digest(String.valueOf(checksumDigit).repeat(64)));
    }
}
