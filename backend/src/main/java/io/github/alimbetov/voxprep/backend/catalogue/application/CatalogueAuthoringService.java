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
import java.util.UUID;
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
        return verticals.saveAndFlush(new VerticalEntity(
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
        return goals.saveAndFlush(new LearningGoalEntity(
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
        entity.updateDetails(requireVertical(verticalId), title, description, sortOrder, availability);
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
        return tracks.saveAndFlush(new LearningTrackEntity(
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
        entity.updateDetails(
                requireGoal(goalId), title, description, levelCode, careerTrackCode, sortOrder, availability);
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
        return collections.saveAndFlush(new LearningCollectionEntity(
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
        entity.updateDetails(requireTrack(trackId), title, description, accessLevel, sortOrder, availability);
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

    private static <T> T save(org.springframework.data.jpa.repository.JpaRepository<T, UUID> repository, T entity) {
        try {
            return repository.saveAndFlush(entity);
        } catch (OptimisticLockingFailureException exception) {
            throw new CatalogueAuthoringConflictException("Catalogue item was modified by another editor", exception);
        }
    }
}
