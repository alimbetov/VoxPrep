package io.github.alimbetov.voxprep.backend.content.localization;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ContentLocalizationRevisionRepository extends JpaRepository<ContentLocalizationRevisionEntity, UUID> {

    Optional<ContentLocalizationRevisionEntity> findTopByContentRevisionIdAndLocaleOrderByLocalizationRevisionNumberDesc(
            UUID contentRevisionId,
            String locale);

    Optional<ContentLocalizationRevisionEntity>
            findTopByContentRevisionIdAndLocaleAndLifecycleAndApprovedAtLessThanEqualOrderByLocalizationRevisionNumberDesc(
                    UUID contentRevisionId,
                    String locale,
                    ContentLocalizationLifecycleStatus lifecycle,
                    Instant approvedAt);

    List<ContentLocalizationRevisionEntity> findAllByContentRevisionIdAndLocaleOrderByLocalizationRevisionNumberAsc(
            UUID contentRevisionId,
            String locale);
}
