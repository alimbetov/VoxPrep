package io.github.alimbetov.voxprep.backend.catalogue.persistence;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface VerticalRepository extends JpaRepository<VerticalEntity, UUID> {

    Optional<VerticalEntity> findByCode(CatalogueCode code);

    List<VerticalEntity> findAllByOrderBySortOrderAscCodeAsc();
}
