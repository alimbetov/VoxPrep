package io.github.alimbetov.voxprep.backend.catalogue.web;

import io.github.alimbetov.voxprep.backend.catalogue.application.CatalogueAdminQueryService;
import io.github.alimbetov.voxprep.backend.catalogue.application.CatalogueAuthoringService;
import io.github.alimbetov.voxprep.backend.catalogue.application.CatalogueSnapshot;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CollectionAccessLevel;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/admin/api/v1/catalogue")
public class AdminCatalogueAuthoringController {

    private final CatalogueAuthoringService authoring;
    private final CatalogueAdminQueryService query;

    public AdminCatalogueAuthoringController(CatalogueAuthoringService authoring, CatalogueAdminQueryService query) {
        this.authoring = authoring;
        this.query = query;
    }

    @GetMapping("/verticals")
    public List<CatalogueSnapshot> listVerticals() {
        return query.listVerticals();
    }

    @GetMapping("/verticals/{id}")
    public CatalogueSnapshot getVertical(@PathVariable UUID id) {
        return query.getVertical(id);
    }

    @PostMapping("/verticals")
    public CatalogueSnapshot createVertical(@Valid @RequestBody VerticalRequest request) {
        var entity = authoring.createVertical(
                new CatalogueCode(request.code()), new CatalogueCode(request.sectionCode()), request.title(),
                request.description(), request.iconAssetId(), request.sortOrder(), availability(request.availability()));
        return query.getVertical(entity.getId());
    }

    @PutMapping("/verticals/{id}")
    public CatalogueSnapshot updateVertical(@PathVariable UUID id, @Valid @RequestBody VerticalRequest request) {
        var entity = authoring.updateVertical(
                id, requireVersion(request.expectedVersion()), new CatalogueCode(request.sectionCode()), request.title(),
                request.description(), request.iconAssetId(), request.sortOrder(), availability(request.availability()));
        return query.getVertical(entity.getId());
    }

    @GetMapping("/goals/{id}")
    public CatalogueSnapshot getGoal(@PathVariable UUID id) {
        return query.getGoal(id);
    }

    @PostMapping("/goals")
    public CatalogueSnapshot createGoal(@Valid @RequestBody GoalRequest request) {
        var entity = authoring.createGoal(
                new CatalogueCode(request.code()), request.verticalId(), request.title(), request.description(),
                request.sortOrder(), availability(request.availability()));
        return query.getGoal(entity.getId());
    }

    @PutMapping("/goals/{id}")
    public CatalogueSnapshot updateGoal(@PathVariable UUID id, @Valid @RequestBody GoalRequest request) {
        var entity = authoring.updateGoal(
                id, requireVersion(request.expectedVersion()), request.verticalId(), request.title(), request.description(),
                request.sortOrder(), availability(request.availability()));
        return query.getGoal(entity.getId());
    }

    @GetMapping("/tracks/{id}")
    public CatalogueSnapshot getTrack(@PathVariable UUID id) {
        return query.getTrack(id);
    }

    @PostMapping("/tracks")
    public CatalogueSnapshot createTrack(@Valid @RequestBody TrackRequest request) {
        var entity = authoring.createTrack(
                new CatalogueCode(request.code()), request.goalId(), request.title(), request.description(),
                new CatalogueCode(request.levelCode()), optionalCode(request.careerTrackCode()), request.sortOrder(),
                availability(request.availability()));
        return query.getTrack(entity.getId());
    }

    @PutMapping("/tracks/{id}")
    public CatalogueSnapshot updateTrack(@PathVariable UUID id, @Valid @RequestBody TrackRequest request) {
        var entity = authoring.updateTrack(
                id, requireVersion(request.expectedVersion()), request.goalId(), request.title(), request.description(),
                new CatalogueCode(request.levelCode()), optionalCode(request.careerTrackCode()), request.sortOrder(),
                availability(request.availability()));
        return query.getTrack(entity.getId());
    }

    @GetMapping("/collections/{id}")
    public CatalogueSnapshot getCollection(@PathVariable UUID id) {
        return query.getCollection(id);
    }

    @PostMapping("/collections")
    public CatalogueSnapshot createCollection(@Valid @RequestBody CollectionRequest request) {
        var entity = authoring.createCollection(
                new CatalogueCode(request.code()), request.trackId(), request.title(), request.description(),
                CollectionAccessLevel.valueOf(request.accessLevel().toUpperCase(Locale.ROOT)), request.sortOrder(),
                availability(request.availability()));
        return query.getCollection(entity.getId());
    }

    @PutMapping("/collections/{id}")
    public CatalogueSnapshot updateCollection(@PathVariable UUID id, @Valid @RequestBody CollectionRequest request) {
        var entity = authoring.updateCollection(
                id, requireVersion(request.expectedVersion()), request.trackId(), request.title(), request.description(),
                CollectionAccessLevel.valueOf(request.accessLevel().toUpperCase(Locale.ROOT)), request.sortOrder(),
                availability(request.availability()));
        return query.getCollection(entity.getId());
    }

    private static AvailabilityStatus availability(String value) {
        return AvailabilityStatus.valueOf(value.toUpperCase(Locale.ROOT));
    }

    private static CatalogueCode optionalCode(String value) {
        return value == null || value.isBlank() ? null : new CatalogueCode(value);
    }

    private static long requireVersion(Long value) {
        if (value == null) {
            throw new IllegalArgumentException("expectedVersion is required for updates");
        }
        return value;
    }

    public record VerticalRequest(
            Long expectedVersion,
            @NotBlank String code,
            @NotBlank String sectionCode,
            @NotBlank String title,
            @NotBlank String description,
            @NotBlank String iconAssetId,
            @Min(0) int sortOrder,
            @NotBlank String availability) {
    }

    public record GoalRequest(
            Long expectedVersion,
            @NotBlank String code,
            @NotNull UUID verticalId,
            @NotBlank String title,
            @NotBlank String description,
            @Min(0) int sortOrder,
            @NotBlank String availability) {
    }

    public record TrackRequest(
            Long expectedVersion,
            @NotBlank String code,
            @NotNull UUID goalId,
            @NotBlank String title,
            @NotBlank String description,
            @NotBlank String levelCode,
            String careerTrackCode,
            @Min(0) int sortOrder,
            @NotBlank String availability) {
    }

    public record CollectionRequest(
            Long expectedVersion,
            @NotBlank String code,
            @NotNull UUID trackId,
            @NotBlank String title,
            @NotBlank String description,
            @NotBlank String accessLevel,
            @Min(0) int sortOrder,
            @NotBlank String availability) {
    }
}
