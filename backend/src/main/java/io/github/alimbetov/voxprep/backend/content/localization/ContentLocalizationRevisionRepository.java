package io.github.alimbetov.voxprep.backend.content.localization;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ContentLocalizationRevisionRepository extends JpaRepository<ContentLocalizationRevisionEntity, UUID> {

    Optional<ContentLocalizationRevisionEntity> findTopByContentRevisionIdAndLocaleOrderByLocalizationRevisionNumberDesc(
            UUID contentRevisionId,
            String locale);

    List<ContentLocalizationRevisionEntity> findAllByContentRevisionIdAndLocaleOrderByLocalizationRevisionNumberAsc(
            UUID contentRevisionId,
            String locale);
}
