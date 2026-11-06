package io.github.alimbetov.voxprep.backend.tts.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

class KokoroModelBindingServiceTest {

    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final KokoroModelBindingService service = new KokoroModelBindingService(jdbc);

    @Test
    void rejectsUnrecognizedVoiceWithoutDatabaseWrites() {
        assertThatThrownBy(() -> service.bind(UUID.randomUUID(), UUID.randomUUID(),
                "arbitrary_voice", "pinned-espeak", BigDecimal.ONE))
                .isInstanceOf(IllegalArgumentException.class);
        verifyNoInteractions(jdbc);
    }

    @Test
    void rejectsUnpinnedPhonemizerAndInvalidSpeed() {
        UUID vm = UUID.randomUUID(), bundle = UUID.randomUUID();
        assertThatThrownBy(() -> service.bind(vm, bundle,
                "af_heart", " ", BigDecimal.ONE))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> service.bind(vm, bundle,
                "bf_emma", "phonemizer-v1", new BigDecimal("2.001")))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> service.bind(vm, bundle,
                "am_michael", "phonemizer-v1", new BigDecimal("1.1234")))
                .isInstanceOf(IllegalArgumentException.class);
        verifyNoInteractions(jdbc);
    }

    @Test
    void refusesIncompleteOrUnapprovedBundle() {
        when(jdbc.update(anyString(), (Object[]) any())).thenReturn(0);
        assertThatThrownBy(() -> service.bind(UUID.randomUUID(), UUID.randomUUID(),
                "af_heart", "phonemizer-pinned", BigDecimal.ONE))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("not eligible");
    }

    @Test
    void lookupWithoutBindingReturnsEmpty() {
        when(jdbc.query(anyString(), any(org.springframework.jdbc.core.RowMapper.class),
                any(UUID.class))).thenReturn(java.util.List.of());
        assertThat(service.find(UUID.randomUUID())).isEmpty();
    }
}
