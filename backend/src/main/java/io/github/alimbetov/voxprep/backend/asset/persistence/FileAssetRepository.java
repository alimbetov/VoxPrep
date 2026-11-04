package io.github.alimbetov.voxprep.backend.asset.persistence;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import org.springframework.data.domain.Pageable;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FileAssetRepository extends JpaRepository<FileAssetEntity, UUID> {

    Optional<FileAssetEntity> findByBucketAndObjectKey(String bucket, String objectKey);

    @Query("select asset.id from FileAssetEntity asset "
            + "where asset.status = :status and asset.createdAt <= :cutoff "
            + "order by asset.createdAt asc, asset.id asc")
    List<UUID> findStaleAssetIds(
            @Param("status") FileAssetStatus status,
            @Param("cutoff") Instant cutoff,
            Pageable page);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select asset from FileAssetEntity asset where asset.id = :id")
    Optional<FileAssetEntity> findByIdForUpdate(@Param("id") UUID id);
}
