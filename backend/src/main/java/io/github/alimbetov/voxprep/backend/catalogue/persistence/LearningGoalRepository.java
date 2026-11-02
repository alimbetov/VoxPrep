package io.github.alimbetov.voxprep.backend.catalogue.persistence;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LearningGoalRepository extends JpaRepository<LearningGoalEntity, UUID> {

    Optional<LearningGoalEntity> findByCode(CatalogueCode code);

    List<LearningGoalEntity> findAllByVertical_IdOrderBySortOrderAscCodeAsc(UUID verticalId);
}
