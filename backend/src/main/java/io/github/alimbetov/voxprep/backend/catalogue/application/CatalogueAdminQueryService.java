package io.github.alimbetov.voxprep.backend.catalogue.application;

import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningCollectionRepository;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningGoalRepository;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningTrackRepository;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.VerticalRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CatalogueAdminQueryService {

    private final VerticalRepository verticals;
    private final LearningGoalRepository goals;
    private final LearningTrackRepository tracks;
    private final LearningCollectionRepository collections;

    public CatalogueAdminQueryService(
            VerticalRepository verticals,
            LearningGoalRepository goals,
            LearningTrackRepository tracks,
            LearningCollectionRepository collections) {
        this.verticals = verticals;
        this.goals = goals;
        this.tracks = tracks;
        this.collections = collections;
    }

    @Transactional(readOnly = true)
    public List<CatalogueSnapshot> listVerticals() {
        return verticals.findAllByOrderBySortOrderAscCodeAsc().stream().map(CatalogueSnapshot::from).toList();
    }

    @Transactional(readOnly = true)
    public List<CatalogueSnapshot> listGoals(UUID verticalId) {
        requireVertical(verticalId);
        return goals.findAllByVertical_IdOrderBySortOrderAscCodeAsc(verticalId).stream()
                .map(CatalogueSnapshot::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<CatalogueSnapshot> listTracks(UUID goalId) {
        requireGoal(goalId);
        return tracks.findAllByGoal_IdOrderBySortOrderAscCodeAsc(goalId).stream()
                .map(CatalogueSnapshot::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<CatalogueSnapshot> listCollections(UUID trackId) {
        requireTrack(trackId);
        return collections.findAllByTrack_IdOrderBySortOrderAscCodeAsc(trackId).stream()
                .map(CatalogueSnapshot::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public CatalogueSnapshot getVertical(UUID id) {
        return CatalogueSnapshot.from(requireVertical(id));
    }

    @Transactional(readOnly = true)
    public CatalogueSnapshot getGoal(UUID id) {
        return CatalogueSnapshot.from(requireGoal(id));
    }

    @Transactional(readOnly = true)
    public CatalogueSnapshot getTrack(UUID id) {
        return CatalogueSnapshot.from(requireTrack(id));
    }

    @Transactional(readOnly = true)
    public CatalogueSnapshot getCollection(UUID id) {
        return collections.findById(id).map(CatalogueSnapshot::from)
                .orElseThrow(() -> new CatalogueAuthoringNotFoundException("collection", id));
    }

    private io.github.alimbetov.voxprep.backend.catalogue.persistence.VerticalEntity requireVertical(UUID id) {
        return verticals.findById(id).orElseThrow(() -> new CatalogueAuthoringNotFoundException("vertical", id));
    }

    private io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningGoalEntity requireGoal(UUID id) {
        return goals.findById(id).orElseThrow(() -> new CatalogueAuthoringNotFoundException("goal", id));
    }

    private io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningTrackEntity requireTrack(UUID id) {
        return tracks.findById(id).orElseThrow(() -> new CatalogueAuthoringNotFoundException("track", id));
    }
}
