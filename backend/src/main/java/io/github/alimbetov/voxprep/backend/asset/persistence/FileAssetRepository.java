package io.github.alimbetov.voxprep.backend.asset.persistence;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FileAssetRepository extends JpaRepository<FileAssetEntity, UUID> {

    Optional<FileAssetEntity> findByBucketAndObjectKey(String bucket, String objectKey);
}
