package io.github.alimbetov.voxprep.backend.catalogue.web.mvc;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueConstraints;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public final class CatalogueMvcForms {

    private CatalogueMvcForms() {}

    private static final String CODE_MESSAGE = "Use uppercase Latin letters (A-Z), digits, dots, underscores or hyphens. Start with a letter or digit; no spaces.";

    private static final String AVAILABILITY_PATTERN = "ACTIVE|INACTIVE";

    public static final class VerticalForm {
        @NotNull @Min(0) private Long expectedVersion = 0L;
        @NotBlank @Size(max = CatalogueCode.MAX_LENGTH) @Pattern(regexp = CatalogueCode.REGEXP, message = CODE_MESSAGE) private String code;
        @NotBlank @Size(max = CatalogueCode.MAX_LENGTH) @Pattern(regexp = CatalogueCode.REGEXP, message = CODE_MESSAGE) private String sectionCode;
        @NotBlank @Size(max = CatalogueConstraints.TITLE_MAX_LENGTH) private String title;
        @NotBlank @Size(max = CatalogueConstraints.DESCRIPTION_MAX_LENGTH) private String description;
        @NotBlank @Size(max = CatalogueConstraints.EXTERNAL_ID_MAX_LENGTH) private String iconAssetId;
        @NotNull @Min(0) private Integer sortOrder = 0;
        @NotBlank @Pattern(regexp = AVAILABILITY_PATTERN) private String availability = "ACTIVE";

        public Long getExpectedVersion() { return expectedVersion; }
        public void setExpectedVersion(Long expectedVersion) { this.expectedVersion = expectedVersion; }
        public String getCode() { return code; }
        public void setCode(String code) { this.code = code; }
        public String getSectionCode() { return sectionCode; }
        public void setSectionCode(String sectionCode) { this.sectionCode = sectionCode; }
        public String getTitle() { return title; }
        public void setTitle(String title) { this.title = title; }
        public String getDescription() { return description; }
        public void setDescription(String description) { this.description = description; }
        public String getIconAssetId() { return iconAssetId; }
        public void setIconAssetId(String iconAssetId) { this.iconAssetId = iconAssetId; }
        public Integer getSortOrder() { return sortOrder; }
        public void setSortOrder(Integer sortOrder) { this.sortOrder = sortOrder; }
        public String getAvailability() { return availability; }
        public void setAvailability(String availability) { this.availability = availability; }
    }

    public static final class GoalForm {
        @NotNull @Min(0) private Long expectedVersion = 0L;
        @NotBlank @Size(max = CatalogueCode.MAX_LENGTH) @Pattern(regexp = CatalogueCode.REGEXP, message = CODE_MESSAGE) private String code;
        @NotNull private UUID verticalId;
        @NotBlank @Size(max = CatalogueConstraints.TITLE_MAX_LENGTH) private String title;
        @NotBlank @Size(max = CatalogueConstraints.DESCRIPTION_MAX_LENGTH) private String description;
        @NotNull @Min(0) private Integer sortOrder = 0;
        @NotBlank @Pattern(regexp = AVAILABILITY_PATTERN) private String availability = "ACTIVE";

        public Long getExpectedVersion() { return expectedVersion; }
        public void setExpectedVersion(Long expectedVersion) { this.expectedVersion = expectedVersion; }
        public String getCode() { return code; }
        public void setCode(String code) { this.code = code; }
        public UUID getVerticalId() { return verticalId; }
        public void setVerticalId(UUID verticalId) { this.verticalId = verticalId; }
        public String getTitle() { return title; }
        public void setTitle(String title) { this.title = title; }
        public String getDescription() { return description; }
        public void setDescription(String description) { this.description = description; }
        public Integer getSortOrder() { return sortOrder; }
        public void setSortOrder(Integer sortOrder) { this.sortOrder = sortOrder; }
        public String getAvailability() { return availability; }
        public void setAvailability(String availability) { this.availability = availability; }
    }

    public static final class TrackForm {
        @NotNull @Min(0) private Long expectedVersion = 0L;
        @NotBlank @Size(max = CatalogueCode.MAX_LENGTH) @Pattern(regexp = CatalogueCode.REGEXP, message = CODE_MESSAGE) private String code;
        @NotNull private UUID goalId;
        @NotBlank @Size(max = CatalogueConstraints.TITLE_MAX_LENGTH) private String title;
        @NotBlank @Size(max = CatalogueConstraints.DESCRIPTION_MAX_LENGTH) private String description;
        @NotBlank @Size(max = CatalogueCode.MAX_LENGTH) @Pattern(regexp = CatalogueCode.REGEXP, message = CODE_MESSAGE) private String levelCode;
        @Size(max = CatalogueCode.MAX_LENGTH) @Pattern(regexp = "^$|" + CatalogueCode.REGEXP, message = CODE_MESSAGE) private String careerTrackCode;
        @NotNull @Min(0) private Integer sortOrder = 0;
        @NotBlank @Pattern(regexp = AVAILABILITY_PATTERN) private String availability = "ACTIVE";

        public Long getExpectedVersion() { return expectedVersion; }
        public void setExpectedVersion(Long expectedVersion) { this.expectedVersion = expectedVersion; }
        public String getCode() { return code; }
        public void setCode(String code) { this.code = code; }
        public UUID getGoalId() { return goalId; }
        public void setGoalId(UUID goalId) { this.goalId = goalId; }
        public String getTitle() { return title; }
        public void setTitle(String title) { this.title = title; }
        public String getDescription() { return description; }
        public void setDescription(String description) { this.description = description; }
        public String getLevelCode() { return levelCode; }
        public void setLevelCode(String levelCode) { this.levelCode = levelCode; }
        public String getCareerTrackCode() { return careerTrackCode; }
        public void setCareerTrackCode(String careerTrackCode) { this.careerTrackCode = careerTrackCode; }
        public Integer getSortOrder() { return sortOrder; }
        public void setSortOrder(Integer sortOrder) { this.sortOrder = sortOrder; }
        public String getAvailability() { return availability; }
        public void setAvailability(String availability) { this.availability = availability; }
    }

    public static final class CollectionForm {
        @NotNull @Min(0) private Long expectedVersion = 0L;
        @NotBlank @Size(max = CatalogueCode.MAX_LENGTH) @Pattern(regexp = CatalogueCode.REGEXP, message = CODE_MESSAGE) private String code;
        @NotNull private UUID trackId;
        @NotBlank @Size(max = CatalogueConstraints.TITLE_MAX_LENGTH) private String title;
        @NotBlank @Size(max = CatalogueConstraints.DESCRIPTION_MAX_LENGTH) private String description;
        @NotBlank @Pattern(regexp = "FREE|FULL") private String accessLevel = "FREE";
        @NotNull @Min(0) private Integer sortOrder = 0;
        @NotBlank @Pattern(regexp = AVAILABILITY_PATTERN) private String availability = "ACTIVE";

        public Long getExpectedVersion() { return expectedVersion; }
        public void setExpectedVersion(Long expectedVersion) { this.expectedVersion = expectedVersion; }
        public String getCode() { return code; }
        public void setCode(String code) { this.code = code; }
        public UUID getTrackId() { return trackId; }
        public void setTrackId(UUID trackId) { this.trackId = trackId; }
        public String getTitle() { return title; }
        public void setTitle(String title) { this.title = title; }
        public String getDescription() { return description; }
        public void setDescription(String description) { this.description = description; }
        public String getAccessLevel() { return accessLevel; }
        public void setAccessLevel(String accessLevel) { this.accessLevel = accessLevel; }
        public Integer getSortOrder() { return sortOrder; }
        public void setSortOrder(Integer sortOrder) { this.sortOrder = sortOrder; }
        public String getAvailability() { return availability; }
        public void setAvailability(String availability) { this.availability = availability; }
    }
}
