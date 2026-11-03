package io.github.alimbetov.voxprep.backend.catalogue.persistence;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CollectionAccessLevel;
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
        name = "catalogue_learning_collection",
        schema = "app",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_catalogue_learning_collection__code",
                columnNames = "code"),
        indexes = @Index(
                name = "ix_catalogue_learning_collection__track_sort_code",
                columnList = "track_id, sort_order, code"))
public class LearningCollectionEntity extends AbstractJpaEntity {

    @Convert(converter = CatalogueCodeConverter.class)
    @Column(name = "code", nullable = false, updatable = false, length = CatalogueCode.MAX_LENGTH)
    private CatalogueCode code;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(
            name = "track_id",
            nullable = false,
            foreignKey = @ForeignKey(name = "fk_catalogue_learning_collection__track"))
    private LearningTrackEntity track;

    @Column(name = "title", nullable = false, length = CatalogueEntityRules.TITLE_MAX_LENGTH)
    private String title;

    @Column(name = "description", nullable = false, length = CatalogueEntityRules.DESCRIPTION_MAX_LENGTH)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "access_level", nullable = false, length = 16)
    private CollectionAccessLevel accessLevel;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

    @Enumerated(EnumType.STRING)
    @Column(name = "availability", nullable = false, length = 16)
    private AvailabilityStatus availability;

    protected LearningCollectionEntity() {
    }

    public LearningCollectionEntity(
            CatalogueCode code,
            LearningTrackEntity track,
            String title,
            String description,
            CollectionAccessLevel accessLevel,
            int sortOrder,
            AvailabilityStatus availability) {
        this.code = Objects.requireNonNull(code, "code");
        updateDetails(track, title, description, accessLevel, sortOrder, availability);
    }

    public void updateDetails(
            LearningTrackEntity track,
            String title,
            String description,
            CollectionAccessLevel accessLevel,
            int sortOrder,
            AvailabilityStatus availability) {
        this.track = Objects.requireNonNull(track, "track");
        this.title = CatalogueEntityRules.requiredText(
                title, "title", CatalogueEntityRules.TITLE_MAX_LENGTH);
        this.description = CatalogueEntityRules.requiredText(
                description, "description", CatalogueEntityRules.DESCRIPTION_MAX_LENGTH);
        this.accessLevel = Objects.requireNonNull(accessLevel, "accessLevel");
        this.sortOrder = CatalogueEntityRules.sortOrder(sortOrder);
        this.availability = Objects.requireNonNull(availability, "availability");
    }

    public CatalogueCode getCode() {
        return code;
    }

    public LearningTrackEntity getTrack() {
        return track;
    }

    public String getTitle() {
        return title;
    }

    public String getDescription() {
        return description;
    }

    public CollectionAccessLevel getAccessLevel() {
        return accessLevel;
    }

    public int getSortOrder() {
        return sortOrder;
    }

    public AvailabilityStatus getAvailability() {
        return availability;
    }
}
