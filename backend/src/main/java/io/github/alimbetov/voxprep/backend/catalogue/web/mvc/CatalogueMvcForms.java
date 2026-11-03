package io.github.alimbetov.voxprep.backend.catalogue.web.mvc;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import java.util.UUID;

public final class CatalogueMvcForms {

    private CatalogueMvcForms() {}

    private static final String AVAILABILITY_PATTERN = "ACTIVE|INACTIVE";

    public static final class VerticalForm {
        private Long expectedVersion = 0L;
        @NotBlank private String code;
        @NotBlank private String sectionCode;
        @NotBlank private String title;
        @NotBlank private String description;
        @NotBlank private String iconAssetId;
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
        private Long expectedVersion = 0L;
        @NotBlank private String code;
        @NotNull private UUID verticalId;
        @NotBlank private String title;
        @NotBlank private String description;
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
        private Long expectedVersion = 0L;
        @NotBlank private String code;
        @NotNull private UUID goalId;
        @NotBlank private String title;
        @NotBlank private String description;
        @NotBlank private String levelCode;
        private String careerTrackCode;
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
        private Long expectedVersion = 0L;
        @NotBlank private String code;
        @NotNull private UUID trackId;
        @NotBlank private String title;
        @NotBlank private String description;
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
