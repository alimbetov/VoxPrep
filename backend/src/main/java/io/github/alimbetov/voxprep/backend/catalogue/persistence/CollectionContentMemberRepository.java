package io.github.alimbetov.voxprep.backend.catalogue.persistence;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CollectionContentMemberRepository
        extends JpaRepository<CollectionContentMemberEntity, UUID> {

    List<CollectionContentMemberEntity> findAllByCollectionIdOrderByPositionAsc(UUID collectionId);

    boolean existsByCollectionIdAndContentRevisionId(UUID collectionId, UUID contentRevisionId);

    List<CollectionContentMemberEntity> findAllByContentRevision_Id(UUID contentRevisionId);
}
