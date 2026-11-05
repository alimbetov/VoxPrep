package io.github.alimbetov.voxprep.backend.catalogue.web.mvc;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.validation.Validation;
import org.junit.jupiter.api.Test;

class CatalogueMvcFormsTest {
    @Test
    void normalizesCatalogueInputsBeforeValidationWithoutChangingTitles() {
        var vertical = new CatalogueMvcForms.VerticalForm();
        vertical.setCode("  java_backend  "); vertical.setSectionCode(" tech ");
        vertical.setTitle("Моя вертикаль");
        var goal = new CatalogueMvcForms.GoalForm(); goal.setCode("Gggggggggggggg1");
        var track = new CatalogueMvcForms.TrackForm(); track.setCode(" java ");
        track.setLevelCode(" b2 "); track.setCareerTrackCode(" backend ");
        var collection = new CatalogueMvcForms.CollectionForm(); collection.setCode(" intro ");
        assertThat(vertical.getCode()).isEqualTo("JAVA_BACKEND");
        assertThat(vertical.getSectionCode()).isEqualTo("TECH");
        assertThat(vertical.getTitle()).isEqualTo("Моя вертикаль");
        assertThat(goal.getCode()).isEqualTo("GGGGGGGGGGGGGG1");
        assertThat(track.getCode()).isEqualTo("JAVA");
        assertThat(track.getLevelCode()).isEqualTo("B2");
        assertThat(track.getCareerTrackCode()).isEqualTo("BACKEND");
        assertThat(collection.getCode()).isEqualTo("INTRO");
    }

    @Test
    void stillRejectsInternalSpacesAndNonLatinCodes() {
        try (var factory = Validation.buildDefaultValidatorFactory()) {
            var validator = factory.getValidator();
            var form = new CatalogueMvcForms.GoalForm();
            form.setCode("two words");
            assertThat(validator.validateProperty(form, "code")).isNotEmpty();
            form.setCode("цель");
            assertThat(validator.validateProperty(form, "code")).isNotEmpty();
            form.setCode("goal_1");
            assertThat(validator.validateProperty(form, "code")).isEmpty();
        }
    }
}
