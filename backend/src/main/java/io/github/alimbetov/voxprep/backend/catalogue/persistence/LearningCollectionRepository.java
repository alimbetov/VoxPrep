package io.github.alimbetov.voxprep.backend.catalogue.persistence;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LearningCollectionRepository extends JpaRepository<LearningCollectionEntity, UUID> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select c from LearningCollectionEntity c where c.id = :id")
    Optional<LearningCollectionEntity> lockCollection(@Param("id") UUID id);

    Optional<LearningCollectionEntity> findByCode(CatalogueCode code);

    List<LearningCollectionEntity> findAllByTrack_IdOrderBySortOrderAscCodeAsc(UUID trackId);
}
