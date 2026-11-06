package io.github.alimbetov.voxprep.backend.tts.application;

import static org.assertj.core.api.Assertions.assertThat;

import java.lang.reflect.Field;
import org.junit.jupiter.api.Test;

/**
 * Structural guard for the mixed-engine rollout: legacy callers cannot claim
 * future KOKORO jobs even if they send the old unversioned request.
 *
 * This is not a substitute for real PostgreSQL concurrent-claim acceptance.
 */
class LegacyPiperClaimIsolationTest {

    @Test
    void genericLegacyClaimIsPiperOnlyBeforeLockingCandidate() throws Exception {
        assertPiperOnly("CLAIM_SQL");
    }

    @Test
    void workerLegacyClaimIsPiperOnlyBeforeLockingCandidate() throws Exception {
        assertPiperOnly("WORKER_CLAIM_SQL");
    }

    private static void assertPiperOnly(String fieldName) throws Exception {
        Field field = TtsJobLeaseService.class.getDeclaredField(fieldName);
        field.setAccessible(true);
        String sql = (String) field.get(null);
        assertThat(sql)
                .contains("JOIN app.tts_voice_model vm ON vm.id = j.voice_model_id")
                .contains("vm.engine = 'PIPER'")
                .contains("FOR UPDATE OF j SKIP LOCKED LIMIT 1");
        assertThat(sql.indexOf("vm.engine = 'PIPER'"))
                .isLessThan(sql.indexOf("FOR UPDATE OF j SKIP LOCKED"));
    }
}
