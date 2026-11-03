package io.github.alimbetov.voxprep.backend.publication.application;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.publication.domain.PublicationCandidateStatus;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateEntity;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateManifestRefRepository;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCandidateRepository;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationCurrentRepository;
import io.github.alimbetov.voxprep.backend.publication.persistence.PublicationReleaseRepository;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class PublicationPublisherStatusInvariantTest {

    @Mock PublicationCandidateRepository candidateRepository;
    @Mock PublicationCandidateManifestRefRepository manifestRepository;
    @Mock PublicationReleaseRepository releaseRepository;
    @Mock PublicationCurrentRepository currentRepository;
    @Mock PublicationCandidateValidator validator;
    @Mock PublicationContentVersionAllocator versionAllocator;

    @Test
    void draftCandidateCannotBePublished() {
        UUID candidateId = UUID.randomUUID();
        PublicationCandidateEntity candidate = new PublicationCandidateEntity(PublicationCandidateStatus.DRAFT);
        when(candidateRepository.findByIdForUpdate(candidateId)).thenReturn(Optional.of(candidate));

        PublicationPublisher publisher = new PublicationPublisher(
                candidateRepository,
                manifestRepository,
                releaseRepository,
                currentRepository,
                validator,
                versionAllocator);

        assertThatThrownBy(() -> publisher.publish(candidateId, Instant.parse("2026-11-03T09:30:00Z")))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("only VALIDATED candidate can be published");
    }
}
