package io.github.alimbetov.voxprep.backend.catalogue.persistence;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.infrastructure.persistence.AbstractJpaEntity;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.util.Objects;

@Entity
@Table(
        name = "catalogue_learning_track",
        schema = "app",
        uniqueConstraints = @UniqueConstraint(name = "uk_catalogue_learning_track__code", columnNames = "code"),
        indexes = @Index(
                name = "ix_catalogue_learning_track__goal_sort_code",
                columnList = "goal_id, sort_order, code"))
public class LearningTrackEntity extends AbstractJpaEntity {

    @Convert(converter = CatalogueCodeConverter.class)
    @Column(name = "code", nullable = false, updatable = false, length = CatalogueCode.MAX_LENGTH)
    private CatalogueCode code;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(
            name = "goal_id",
            nullable = false,
            foreignKey = @ForeignKey(name = "fk_catalogue_learning_track__goal"))
    private LearningGoalEntity goal;

    @Column(name = "title", nullable = false, length = CatalogueEntityRules.TITLE_MAX_LENGTH)
    private String title;

    @Column(name = "description", nullable = false, length = CatalogueEntityRules.DESCRIPTION_MAX_LENGTH)
    private String description;

    @Convert(converter = CatalogueCodeConverter.class)
    @Column(name = "level_code", nullable = false, length = CatalogueCode.MAX_LENGTH)
    private CatalogueCode levelCode;

    @Convert(converter = CatalogueCodeConverter.class)
    @Column(name = "career_track_code", length = CatalogueCode.MAX_LENGTH)
    private CatalogueCode careerTrackCode;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

    @Enumerated(EnumType.STRING)
    @Column(name = "availability", nullable = false, length = 16)
    private AvailabilityStatus availability;

    protected LearningTrackEntity() {
    }

    public LearningTrackEntity(
            CatalogueCode code,
            LearningGoalEntity goal,
            String title,
            String description,
            CatalogueCode levelCode,
            CatalogueCode careerTrackCode,
            int sortOrder,
            AvailabilityStatus availability) {
        this.code = Objects.requireNonNull(code, "code");
        updateDetails(goal, title, description, levelCode, careerTrackCode, sortOrder, availability);
    }

    public void updateDetails(
            LearningGoalEntity goal,
            String title,
            String description,
            CatalogueCode levelCode,
            CatalogueCode careerTrackCode,
            int sortOrder,
            AvailabilityStatus availability) {
        this.goal = Objects.requireNonNull(goal, "goal");
        this.title = CatalogueEntityRules.requiredText(
                title, "title", CatalogueEntityRules.TITLE_MAX_LENGTH);
        this.description = CatalogueEntityRules.requiredText(
                description, "description", CatalogueEntityRules.DESCRIPTION_MAX_LENGTH);
        this.levelCode = Objects.requireNonNull(levelCode, "levelCode");
        this.careerTrackCode = careerTrackCode;
        this.sortOrder = CatalogueEntityRules.sortOrder(sortOrder);
        this.availability = Objects.requireNonNull(availability, "availability");
    }

    public CatalogueCode getCode() {
        return code;
    }

    public LearningGoalEntity getGoal() {
        return goal;
    }

    public String getTitle() {
        return title;
    }

    public String getDescription() {
        return description;
    }

    public CatalogueCode getLevelCode() {
        return levelCode;
    }

    public CatalogueCode getCareerTrackCode() {
        return careerTrackCode;
    }

    public int getSortOrder() {
        return sortOrder;
    }

    public AvailabilityStatus getAvailability() {
        return availability;
    }
}
