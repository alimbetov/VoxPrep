package io.github.alimbetov.voxprep.backend.catalogue.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

class CatalogueCodeTest {

    @Test
    void preservesValidContractCodeExactly() {
        var code = new CatalogueCode("SOFTWARE_ENGINEERING.V2");

        assertThat(code.value()).isEqualTo("SOFTWARE_ENGINEERING.V2");
    }

    @Test
    void rejectsLowercaseWhitespaceAndSilentNormalizationCases() {
        assertThatThrownBy(() -> new CatalogueCode("goal_alpha"))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new CatalogueCode(" GOAL_ALPHA"))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new CatalogueCode("GOAL ALPHA"))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
