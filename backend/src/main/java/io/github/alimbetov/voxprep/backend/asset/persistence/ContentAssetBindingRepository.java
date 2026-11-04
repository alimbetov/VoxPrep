package io.github.alimbetov.voxprep.backend.asset.persistence;

import io.github.alimbetov.voxprep.backend.asset.domain.ContentAssetRole;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ContentAssetBindingRepository extends JpaRepository<ContentAssetBindingEntity, UUID> {

    Optional<ContentAssetBindingEntity> findByContentRevision_IdAndRole(
            UUID contentRevisionId,
            ContentAssetRole role);

    List<ContentAssetBindingEntity> findAllByContentRevision_IdOrderByRoleAsc(UUID contentRevisionId);

    List<ContentAssetBindingEntity> findAllByFileAsset_Id(UUID fileAssetId);
}
