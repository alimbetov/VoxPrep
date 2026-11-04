package io.github.alimbetov.voxprep.backend.catalogue.application;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CollectionAccessLevel;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningCollectionEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningCollectionRepository;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningGoalEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningGoalRepository;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningTrackEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningTrackRepository;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.VerticalEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.VerticalRepository;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import java.util.Objects;
import java.util.UUID;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CatalogueAuthoringService {

    private final VerticalRepository verticals;
    private final LearningGoalRepository goals;
    private final LearningTrackRepository tracks;
    private final LearningCollectionRepository collections;

    public CatalogueAuthoringService(
            VerticalRepository verticals,
            LearningGoalRepository goals,
            LearningTrackRepository tracks,
            LearningCollectionRepository collections) {
        this.verticals = verticals;
        this.goals = goals;
        this.tracks = tracks;
        this.collections = collections;
    }

    @Transactional
    public VerticalEntity createVertical(
            CatalogueCode code,
            CatalogueCode sectionCode,
            String title,
            String description,
            String iconAssetId,
            int sortOrder,
            AvailabilityStatus availability) {
        return save(verticals, new VerticalEntity(
                code, sectionCode, title, description, iconAssetId, sortOrder, availability));
    }

    @Transactional
    public VerticalEntity updateVertical(
            UUID id,
            long expectedVersion,
            CatalogueCode sectionCode,
            String title,
            String description,
            String iconAssetId,
            int sortOrder,
            AvailabilityStatus availability) {
        var entity = requireVertical(id);
        requireVersion(entity.getVersion(), expectedVersion);
        entity.updateDetails(sectionCode, title, description, iconAssetId, sortOrder, availability);
        return save(verticals, entity);
    }

    @Transactional
    public LearningGoalEntity createGoal(
            CatalogueCode code,
            UUID verticalId,
            String title,
            String description,
            int sortOrder,
            AvailabilityStatus availability) {
        return save(goals, new LearningGoalEntity(
                code, requireVertical(verticalId), title, description, sortOrder, availability));
    }

    @Transactional
    public LearningGoalEntity updateGoal(
            UUID id,
            long expectedVersion,
            UUID verticalId,
            String title,
            String description,
            int sortOrder,
            AvailabilityStatus availability) {
        var entity = requireGoal(id);
        requireVersion(entity.getVersion(), expectedVersion);
        requireSameParent("goal", id, "vertical", entity.getVertical().getId(), verticalId);
        entity.updateDetails(entity.getVertical(), title, description, sortOrder, availability);
        return save(goals, entity);
    }

    @Transactional
    public LearningTrackEntity createTrack(
            CatalogueCode code,
            UUID goalId,
            String title,
            String description,
            CatalogueCode levelCode,
            CatalogueCode careerTrackCode,
            int sortOrder,
            AvailabilityStatus availability) {
        return save(tracks, new LearningTrackEntity(
                code, requireGoal(goalId), title, description, levelCode, careerTrackCode, sortOrder, availability));
    }

    @Transactional
    public LearningTrackEntity updateTrack(
            UUID id,
            long expectedVersion,
            UUID goalId,
            String title,
            String description,
            CatalogueCode levelCode,
            CatalogueCode careerTrackCode,
            int sortOrder,
            AvailabilityStatus availability) {
        var entity = requireTrack(id);
        requireVersion(entity.getVersion(), expectedVersion);
        requireSameParent("track", id, "goal", entity.getGoal().getId(), goalId);
        entity.updateDetails(
                entity.getGoal(), title, description, levelCode, careerTrackCode, sortOrder, availability);
        return save(tracks, entity);
    }

    @Transactional
    public LearningCollectionEntity createCollection(
            CatalogueCode code,
            UUID trackId,
            String title,
            String description,
            CollectionAccessLevel accessLevel,
            int sortOrder,
            AvailabilityStatus availability) {
        return save(collections, new LearningCollectionEntity(
                code, requireTrack(trackId), title, description, accessLevel, sortOrder, availability));
    }

    @Transactional
    public LearningCollectionEntity updateCollection(
            UUID id,
            long expectedVersion,
            UUID trackId,
            String title,
            String description,
            CollectionAccessLevel accessLevel,
            int sortOrder,
            AvailabilityStatus availability) {
        var entity = requireCollection(id);
        requireVersion(entity.getVersion(), expectedVersion);
        requireSameParent("collection", id, "track", entity.getTrack().getId(), trackId);
        entity.updateDetails(entity.getTrack(), title, description, accessLevel, sortOrder, availability);
        return save(collections, entity);
    }

    private VerticalEntity requireVertical(UUID id) {
        return verticals.findById(id).orElseThrow(() -> new CatalogueAuthoringNotFoundException("vertical", id));
    }

    private LearningGoalEntity requireGoal(UUID id) {
        return goals.findById(id).orElseThrow(() -> new CatalogueAuthoringNotFoundException("goal", id));
    }

    private LearningTrackEntity requireTrack(UUID id) {
        return tracks.findById(id).orElseThrow(() -> new CatalogueAuthoringNotFoundException("track", id));
    }

    private LearningCollectionEntity requireCollection(UUID id) {
        return collections.findById(id).orElseThrow(() -> new CatalogueAuthoringNotFoundException("collection", id));
    }

    private static void requireVersion(long actualVersion, long expectedVersion) {
        if (actualVersion != expectedVersion) {
            throw new CatalogueAuthoringConflictException(
                    "Stale catalogue version: expected " + expectedVersion + " but was " + actualVersion);
        }
    }

    private static void requireSameParent(
            String entityType,
            UUID entityId,
            String parentType,
            UUID actualParentId,
            UUID requestedParentId) {
        if (!Objects.equals(actualParentId, requestedParentId)) {
            throw new CatalogueAuthoringConflictException(
                    "Cannot move " + entityType + " " + entityId + " to another " + parentType);
        }
    }

    private static <T> T save(org.springframework.data.jpa.repository.JpaRepository<T, UUID> repository, T entity) {
        try {
            return repository.saveAndFlush(entity);
        } catch (OptimisticLockingFailureException exception) {
            throw new CatalogueAuthoringConflictException("Catalogue item was modified by another editor", exception);
        } catch (DataIntegrityViolationException exception) {
            throw new CatalogueAuthoringConflictException("Catalogue item conflicts with existing data", exception);
        }
    }
}
