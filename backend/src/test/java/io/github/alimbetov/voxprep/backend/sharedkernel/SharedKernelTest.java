package io.github.alimbetov.voxprep.backend.sharedkernel;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

class SharedKernelTest {

    @Test
    void stableCodeIsOpaqueAndCaseSensitive() {
        var code = new StableCode("Career-EN_01");

        assertThat(code.value()).isEqualTo("Career-EN_01");
        assertThat(code.toString()).isEqualTo("Career-EN_01");
    }

    @Test
    void stableCodeRejectsSilentNormalizationCases() {
        assertThatThrownBy(() -> new StableCode(" code"))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new StableCode("code "))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new StableCode("code\nvalue"))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new StableCode("x".repeat(StableCode.MAX_LENGTH + 1)))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void revisionNumbersStartAtOneAndAdvanceExactly() {
        var first = new RevisionNumber(1);

        assertThat(first.next()).isEqualTo(new RevisionNumber(2));
        assertThatThrownBy(() -> new RevisionNumber(0))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
