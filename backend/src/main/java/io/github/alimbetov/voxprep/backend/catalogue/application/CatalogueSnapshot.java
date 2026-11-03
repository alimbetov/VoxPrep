package io.github.alimbetov.voxprep.backend.catalogue.application;

import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningCollectionEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningGoalEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningTrackEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.VerticalEntity;
import java.util.UUID;

public record CatalogueSnapshot(
        UUID id,
        long version,
        String type,
        String code,
        UUID parentId,
        String parentCode,
        String title,
        String description,
        String sectionCode,
        String iconAssetId,
        String levelCode,
        String careerTrackCode,
        String accessLevel,
        int sortOrder,
        String availability) {

    public static CatalogueSnapshot from(VerticalEntity value) {
        return new CatalogueSnapshot(
                value.getId(), value.getVersion(), "VERTICAL", value.getCode().value(),
                null, null, value.getTitle(), value.getDescription(), value.getSectionCode().value(),
                value.getIconAssetId(), null, null, null, value.getSortOrder(), value.getAvailability().name());
    }

    public static CatalogueSnapshot from(LearningGoalEntity value) {
        return new CatalogueSnapshot(
                value.getId(), value.getVersion(), "GOAL", value.getCode().value(),
                value.getVertical().getId(), value.getVertical().getCode().value(),
                value.getTitle(), value.getDescription(), null, null, null, null, null,
                value.getSortOrder(), value.getAvailability().name());
    }

    public static CatalogueSnapshot from(LearningTrackEntity value) {
        return new CatalogueSnapshot(
                value.getId(), value.getVersion(), "TRACK", value.getCode().value(),
                value.getGoal().getId(), value.getGoal().getCode().value(),
                value.getTitle(), value.getDescription(), null, null, value.getLevelCode().value(),
                value.getCareerTrackCode() == null ? null : value.getCareerTrackCode().value(),
                null, value.getSortOrder(), value.getAvailability().name());
    }

    public static CatalogueSnapshot from(LearningCollectionEntity value) {
        return new CatalogueSnapshot(
                value.getId(), value.getVersion(), "COLLECTION", value.getCode().value(),
                value.getTrack().getId(), value.getTrack().getCode().value(),
                value.getTitle(), value.getDescription(), null, null, null, null,
                value.getAccessLevel().name(), value.getSortOrder(), value.getAvailability().name());
    }
}
