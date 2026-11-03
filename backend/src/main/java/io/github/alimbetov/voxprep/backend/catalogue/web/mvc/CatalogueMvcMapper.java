package io.github.alimbetov.voxprep.backend.catalogue.web.mvc;

import io.github.alimbetov.voxprep.backend.catalogue.application.CatalogueSnapshot;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CollectionAccessLevel;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import java.util.Locale;
import org.springframework.stereotype.Component;

@Component
public final class CatalogueMvcMapper {

    public CatalogueMvcForms.VerticalForm toVerticalForm(CatalogueSnapshot snapshot) {
        var form = new CatalogueMvcForms.VerticalForm();
        form.setExpectedVersion(snapshot.version());
        form.setCode(snapshot.code());
        form.setSectionCode(snapshot.sectionCode());
        form.setTitle(snapshot.title());
        form.setDescription(snapshot.description());
        form.setIconAssetId(snapshot.iconAssetId());
        form.setSortOrder(snapshot.sortOrder());
        form.setAvailability(snapshot.availability());
        return form;
    }

    public CatalogueMvcForms.GoalForm toGoalForm(CatalogueSnapshot snapshot) {
        var form = new CatalogueMvcForms.GoalForm();
        form.setExpectedVersion(snapshot.version());
        form.setCode(snapshot.code());
        form.setVerticalId(snapshot.parentId());
        form.setTitle(snapshot.title());
        form.setDescription(snapshot.description());
        form.setSortOrder(snapshot.sortOrder());
        form.setAvailability(snapshot.availability());
        return form;
    }

    public CatalogueMvcForms.TrackForm toTrackForm(CatalogueSnapshot snapshot) {
        var form = new CatalogueMvcForms.TrackForm();
        form.setExpectedVersion(snapshot.version());
        form.setCode(snapshot.code());
        form.setGoalId(snapshot.parentId());
        form.setTitle(snapshot.title());
        form.setDescription(snapshot.description());
        form.setLevelCode(snapshot.levelCode());
        form.setCareerTrackCode(snapshot.careerTrackCode());
        form.setSortOrder(snapshot.sortOrder());
        form.setAvailability(snapshot.availability());
        return form;
    }

    public CatalogueMvcForms.CollectionForm toCollectionForm(CatalogueSnapshot snapshot) {
        var form = new CatalogueMvcForms.CollectionForm();
        form.setExpectedVersion(snapshot.version());
        form.setCode(snapshot.code());
        form.setTrackId(snapshot.parentId());
        form.setTitle(snapshot.title());
        form.setDescription(snapshot.description());
        form.setAccessLevel(snapshot.accessLevel());
        form.setSortOrder(snapshot.sortOrder());
        form.setAvailability(snapshot.availability());
        return form;
    }

    public CatalogueCode code(String value) {
        return new CatalogueCode(value);
    }

    public CatalogueCode optionalCode(String value) {
        return value == null || value.isBlank() ? null : new CatalogueCode(value);
    }

    public AvailabilityStatus availability(String value) {
        return AvailabilityStatus.valueOf(value.toUpperCase(Locale.ROOT));
    }

    public CollectionAccessLevel accessLevel(String value) {
        return CollectionAccessLevel.valueOf(value.toUpperCase(Locale.ROOT));
    }
}
