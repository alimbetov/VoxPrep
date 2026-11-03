package io.github.alimbetov.voxprep.backend.publication.persistence;

import jakarta.persistence.LockModeType;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PublicationCandidateRepository extends JpaRepository<PublicationCandidateEntity, UUID> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select candidate from PublicationCandidateEntity candidate where candidate.id = :id")
    Optional<PublicationCandidateEntity> findByIdForUpdate(@Param("id") UUID id);
}
