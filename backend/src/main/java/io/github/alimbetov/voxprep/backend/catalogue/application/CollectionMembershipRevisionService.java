package io.github.alimbetov.voxprep.backend.catalogue.application;

import io.github.alimbetov.voxprep.backend.catalogue.persistence.CollectionContentMemberEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.CollectionContentMemberRepository;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningCollectionRepository;
import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import java.util.Objects;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Atomically replace one collection slot's exact revision for the next
 * publication. Existing immutable publication snapshots are unaffected.
 */
@Service
public class CollectionMembershipRevisionService {
    private final LearningCollectionRepository collections;
    private final CollectionContentMemberRepository members;
    private final ContentRevisionRepository revisions;

    public CollectionMembershipRevisionService(LearningCollectionRepository collections,
            CollectionContentMemberRepository members, ContentRevisionRepository revisions) {
        this.collections = collections;
        this.members = members;
        this.revisions = revisions;
    }

    /**
     * Appends one exact approved revision. The collection row is locked so
     * simultaneous editors cannot allocate the same contiguous position.
     */
    @Transactional
    public CollectionContentMemberEntity append(UUID collectionId, UUID revisionId) {
        var collection = collections.lockCollection(Objects.requireNonNull(collectionId))
                .orElseThrow(() -> new IllegalArgumentException("Collection not found"));
        var revision = revisions.findById(Objects.requireNonNull(revisionId))
                .orElseThrow(() -> new IllegalArgumentException("Content revision not found"));
        if (revision.getLifecycle() != ContentLifecycleStatus.APPROVED
                && revision.getLifecycle() != ContentLifecycleStatus.PUBLISHED) {
            throw new IllegalStateException("Only APPROVED or PUBLISHED content can be assigned to a collection");
        }
        var assigned = members.findAllByCollectionIdOrderByPositionAsc(collectionId);
        if (assigned.stream().anyMatch(member -> member.getContentRevision().getId().equals(revisionId))) {
            throw new IllegalArgumentException("Exact revision already belongs to collection");
        }
        if (assigned.stream().anyMatch(member -> member.getContentRevision().getContentCode()
                .equals(revision.getContentCode())
                && member.getContentRevision().getContentType() == revision.getContentType())) {
            throw new IllegalArgumentException("Collection already contains this content identity; replace revision instead");
        }
        for (int position = 0; position < assigned.size(); position++) {
            if (assigned.get(position).getPosition() != position) {
                throw new IllegalStateException("Existing collection positions are not contiguous");
            }
        }
        return members.saveAndFlush(new CollectionContentMemberEntity(collection, assigned.size(), revision));
    }

    @Transactional
    public void replace(UUID collectionId, UUID oldMemberId, UUID newRevisionId) {
        var collection = collections.lockCollection(Objects.requireNonNull(collectionId))
                .orElseThrow(() -> new IllegalArgumentException("Collection not found"));
        var member = members.findById(Objects.requireNonNull(oldMemberId))
                .orElseThrow(() -> new IllegalArgumentException("Collection member not found"));
        if (!member.getCollection().getId().equals(collectionId)) {
            throw new IllegalArgumentException("Member belongs to a different collection");
        }
        var previous = member.getContentRevision();
        var next = revisions.findById(Objects.requireNonNull(newRevisionId))
                .orElseThrow(() -> new IllegalArgumentException("New revision not found"));
        if (!previous.getContentCode().equals(next.getContentCode())
                || previous.getContentType() != next.getContentType()
                || next.getRevisionNumber().value() <= previous.getRevisionNumber().value()) {
            throw new IllegalArgumentException("Replacement must be a newer revision of the same content");
        }
        if (next.getLifecycle() != ContentLifecycleStatus.APPROVED
                && next.getLifecycle() != ContentLifecycleStatus.PUBLISHED) {
            throw new IllegalStateException("Replacement revision must be APPROVED or PUBLISHED");
        }
        if (members.existsByCollectionIdAndContentRevisionId(collectionId, newRevisionId)) {
            throw new IllegalArgumentException("Replacement revision already belongs to this collection");
        }
        int position = member.getPosition();
        members.delete(member);
        members.flush();
        members.saveAndFlush(new CollectionContentMemberEntity(collection, position, next));
    }
}
