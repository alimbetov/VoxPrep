package io.github.alimbetov.voxprep.backend.publication.persistence;

import jakarta.persistence.LockModeType;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PublicationCurrentRepository extends JpaRepository<PublicationCurrentEntity, Short> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select current from PublicationCurrentEntity current where current.singletonId = :id")
    Optional<PublicationCurrentEntity> findByIdForUpdate(@Param("id") short id);
}
