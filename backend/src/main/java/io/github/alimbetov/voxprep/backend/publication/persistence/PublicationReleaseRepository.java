package io.github.alimbetov.voxprep.backend.publication.persistence;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PublicationReleaseRepository extends JpaRepository<PublicationReleaseEntity, UUID> {

    Optional<PublicationReleaseEntity> findByContentVersion(long contentVersion);

    @Query("select release from PublicationReleaseEntity release where release.candidate.id = :candidateId")
    Optional<PublicationReleaseEntity> findByCandidateId(@Param("candidateId") UUID candidateId);
}
