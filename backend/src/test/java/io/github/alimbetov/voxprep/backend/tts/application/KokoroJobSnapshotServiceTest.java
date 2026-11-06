package io.github.alimbetov.voxprep.backend.tts.application;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;

import java.math.BigDecimal;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

class KokoroJobSnapshotServiceTest {
    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final KokoroJobSnapshotService snapshots = new KokoroJobSnapshotService(jdbc);

    private static KokoroModelBindingService.Binding binding(UUID voiceModelId) {
        return new KokoroModelBindingService.Binding(
                voiceModelId, UUID.randomUUID(), "kokoro-english-3voice",
                "a".repeat(64), "af_heart", "voices/af_heart.bin",
                "b".repeat(64), "espeak-ng-pinned",
                new BigDecimal("1.000"));
    }

    @Test
    void bindingFromAnotherVoiceModelCannotBeSnapshotted() {
        assertThatThrownBy(() -> snapshots.attach(
                UUID.randomUUID(), UUID.randomUUID(),
                binding(UUID.randomUUID()), "kokoro-runtime-v1", "c".repeat(64)))
                .isInstanceOf(IllegalArgumentException.class);
        verifyNoInteractions(jdbc);
    }

    @Test
    void invalidFingerprintOrRuntimeCannotBeStored() {
        UUID modelId = UUID.randomUUID();
        var pinned = binding(modelId);
        assertThatThrownBy(() -> snapshots.attach(
                UUID.randomUUID(), modelId, pinned, " ", "c".repeat(64)))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> snapshots.attach(
                UUID.randomUUID(), modelId, pinned, "runtime-pinned", "wrong"))
                .isInstanceOf(IllegalArgumentException.class);
        verifyNoInteractions(jdbc);
    }
}
