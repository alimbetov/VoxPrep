package io.github.alimbetov.voxprep.backend.catalogue.persistence;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LearningCollectionRepository extends JpaRepository<LearningCollectionEntity, UUID> {

    Optional<LearningCollectionEntity> findByCode(CatalogueCode code);

    List<LearningCollectionEntity> findAllByTrack_IdOrderBySortOrderAscCodeAsc(UUID trackId);
}
