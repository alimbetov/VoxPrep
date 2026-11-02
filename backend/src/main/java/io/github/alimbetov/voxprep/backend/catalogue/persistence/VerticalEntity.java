package io.github.alimbetov.voxprep.backend.catalogue.persistence;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.infrastructure.persistence.AbstractJpaEntity;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.util.Objects;

@Entity
@Table(
        name = "catalogue_vertical",
        schema = "app",
        uniqueConstraints = @UniqueConstraint(name = "uk_catalogue_vertical__code", columnNames = "code"),
        indexes = @Index(name = "ix_catalogue_vertical__sort_order_code", columnList = "sort_order, code"))
public class VerticalEntity extends AbstractJpaEntity {

    @Convert(converter = CatalogueCodeConverter.class)
    @Column(name = "code", nullable = false, updatable = false, length = CatalogueCode.MAX_LENGTH)
    private CatalogueCode code;

    @Convert(converter = CatalogueCodeConverter.class)
    @Column(name = "section_code", nullable = false, length = CatalogueCode.MAX_LENGTH)
    private CatalogueCode sectionCode;

    @Column(name = "title", nullable = false, length = CatalogueEntityRules.TITLE_MAX_LENGTH)
    private String title;

    @Column(name = "description", nullable = false, length = CatalogueEntityRules.DESCRIPTION_MAX_LENGTH)
    private String description;

    @Column(name = "icon_asset_id", nullable = false, length = CatalogueEntityRules.EXTERNAL_ID_MAX_LENGTH)
    private String iconAssetId;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

    @Enumerated(EnumType.STRING)
    @Column(name = "availability", nullable = false, length = 16)
    private AvailabilityStatus availability;

    protected VerticalEntity() {
    }

    public VerticalEntity(
            CatalogueCode code,
            CatalogueCode sectionCode,
            String title,
            String description,
            String iconAssetId,
            int sortOrder,
            AvailabilityStatus availability) {
        this.code = Objects.requireNonNull(code, "code");
        updateDetails(sectionCode, title, description, iconAssetId, sortOrder, availability);
    }

    public void updateDetails(
            CatalogueCode sectionCode,
            String title,
            String description,
            String iconAssetId,
            int sortOrder,
            AvailabilityStatus availability) {
        this.sectionCode = Objects.requireNonNull(sectionCode, "sectionCode");
        this.title = CatalogueEntityRules.requiredText(
                title, "title", CatalogueEntityRules.TITLE_MAX_LENGTH);
        this.description = CatalogueEntityRules.requiredText(
                description, "description", CatalogueEntityRules.DESCRIPTION_MAX_LENGTH);
        this.iconAssetId = CatalogueEntityRules.requiredText(
                iconAssetId, "iconAssetId", CatalogueEntityRules.EXTERNAL_ID_MAX_LENGTH);
        this.sortOrder = CatalogueEntityRules.sortOrder(sortOrder);
        this.availability = Objects.requireNonNull(availability, "availability");
    }

    public CatalogueCode getCode() {
        return code;
    }

    public CatalogueCode getSectionCode() {
        return sectionCode;
    }

    public String getTitle() {
        return title;
    }

    public String getDescription() {
        return description;
    }

    public String getIconAssetId() {
        return iconAssetId;
    }

    public int getSortOrder() {
        return sortOrder;
    }

    public AvailabilityStatus getAvailability() {
        return availability;
    }
}
