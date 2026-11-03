package io.github.alimbetov.voxprep.backend.publication.persistence;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PublicationCandidateManifestRefRepository
        extends JpaRepository<PublicationCandidateManifestRefEntity, UUID> {

    boolean existsByCandidateId(UUID candidateId);

    List<PublicationCandidateManifestRefEntity> findAllByCandidateIdOrderByPositionAsc(UUID candidateId);
}
