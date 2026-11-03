package io.github.alimbetov.voxprep.backend.publication.persistence;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PublicationCandidateRepository extends JpaRepository<PublicationCandidateEntity, UUID> {
}
