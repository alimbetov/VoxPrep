package io.github.alimbetov.voxprep.backend.content.review;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ContentReviewAuditRepository extends JpaRepository<ContentReviewAuditEntity, UUID> {

    List<ContentReviewAuditEntity> findAllByContentRevisionIdOrderByOccurredAtAscIdAsc(UUID contentRevisionId);
}
