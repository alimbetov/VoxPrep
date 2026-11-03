package io.github.alimbetov.voxprep.backend.catalogue.persistence;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LearningTrackRepository extends JpaRepository<LearningTrackEntity, UUID> {

    Optional<LearningTrackEntity> findByCode(CatalogueCode code);

    List<LearningTrackEntity> findAllByGoal_IdOrderBySortOrderAscCodeAsc(UUID goalId);
}
