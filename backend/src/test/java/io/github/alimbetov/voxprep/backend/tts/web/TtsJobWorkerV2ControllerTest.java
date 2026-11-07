package io.github.alimbetov.voxprep.backend.tts.web;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.tts.application.TtsJobLeaseService;
import io.github.alimbetov.voxprep.backend.tts.application.WorkerApiKeyVerifier;
import io.github.alimbetov.voxprep.backend.tts.application.WorkerDeliveryProperties;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import java.util.Optional;
import org.junit.jupiter.api.Test;

class TtsJobWorkerV2ControllerTest {
    private final TtsJobLeaseService leases = mock(TtsJobLeaseService.class);
    private final WorkerDeliveryProperties properties = credentials();

    private static WorkerDeliveryProperties credentials() {
        var config = new WorkerDeliveryProperties();
        config.setApiKey("piper-test-secret");
        config.setKokoroApiKey("kokoro-test-secret");
        return config;
    }

    private TtsJobWorkerV2Controller controller() {
        return new TtsJobWorkerV2Controller(leases, new WorkerApiKeyVerifier(properties), properties);
    }

    @Test
    void clientCannotClaimKokoroWorkWithPiperIdentity() {
        var result = controller().claim("Bearer piper-test-secret",
                new TtsJobWorkerV2Controller.ClaimRequestV2("piper-01", TtsEngine.KOKORO));
        assertThat(result.getStatusCode().value()).isEqualTo(403);
        verify(leases, never()).claimNextForEngine(any(), any(), any());
    }

    @Test
    void validKokoroIdentityIsNotYetAllowedToClaimJobs() {
        var result = controller().claim("Bearer kokoro-test-secret",
                new TtsJobWorkerV2Controller.ClaimRequestV2("kokoro-01", TtsEngine.KOKORO));
        assertThat(result.getStatusCode().value()).isEqualTo(503);
        verify(leases, never()).claimNextForEngine(any(), any(), any());
    }

    @Test
    void piperV2ClaimFiltersByAuthenticatedEngine() {
        when(leases.claimNextForEngine(any(), any(), any())).thenReturn(Optional.empty());
        var result = controller().claim("Bearer piper-test-secret",
                new TtsJobWorkerV2Controller.ClaimRequestV2("piper-01", TtsEngine.PIPER));
        assertThat(result.getStatusCode().value()).isEqualTo(204);
        verify(leases).claimNextForEngine("piper-01", TtsEngine.PIPER, properties.getLeaseDuration());
    }

    @Test
    void rejectsMissingIdentityAndInvalidWorkerId() {
        assertThat(controller().claim(null,
                new TtsJobWorkerV2Controller.ClaimRequestV2("x", TtsEngine.PIPER))
                .getStatusCode().value()).isEqualTo(401);
        assertThat(controller().claim("Bearer piper-test-secret",
                new TtsJobWorkerV2Controller.ClaimRequestV2(" ", TtsEngine.PIPER))
                .getStatusCode().value()).isEqualTo(400);
        verify(leases, never()).claimNextForEngine(any(), any(), any());
    }
}
