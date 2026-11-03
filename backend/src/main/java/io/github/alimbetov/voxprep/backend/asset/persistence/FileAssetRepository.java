package io.github.alimbetov.voxprep.backend.asset.persistence;

import java.util.Optional;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FileAssetRepository extends JpaRepository<FileAssetEntity, UUID> {

    Optional<FileAssetEntity> findByBucketAndObjectKey(String bucket, String objectKey);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select asset from FileAssetEntity asset where asset.id = :id")
    Optional<FileAssetEntity> findByIdForUpdate(@Param("id") UUID id);
}
