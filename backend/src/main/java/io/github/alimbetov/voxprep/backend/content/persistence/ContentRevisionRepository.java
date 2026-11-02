package io.github.alimbetov.voxprep.backend.content.persistence;

import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ContentRevisionRepository extends JpaRepository<ContentRevisionEntity, UUID> {

    @Query(value = """
            select id
              from app.content_revision
             where content_code = :contentCode
               and content_type = :contentType
               and revision_number = :revisionNumber
            """, nativeQuery = true)
    Optional<UUID> findIdByExactIdentity(
            @Param("contentCode") String contentCode,
            @Param("contentType") String contentType,
            @Param("revisionNumber") int revisionNumber);

    default Optional<ContentRevisionEntity> findExact(ContentRevisionIdentity identity) {
        return findIdByExactIdentity(
                        identity.contentCode().value(),
                        identity.contentType().wireName(),
                        identity.revisionNumber().value())
                .flatMap(this::findById);
    }
}
