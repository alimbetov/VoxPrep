package io.github.alimbetov.voxprep.backend.tts.web;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.tts.application.TtsJobLeaseService;
import io.github.alimbetov.voxprep.backend.tts.application.TtsOutputFinalizationService;
import io.github.alimbetov.voxprep.backend.tts.application.WorkerApiKeyVerifier;
import io.github.alimbetov.voxprep.backend.tts.application.WorkerDeliveryProperties;
import io.github.alimbetov.voxprep.backend.tts.domain.TtsEngine;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

class TtsJobWorkerV2LifecycleControllerTest {

    private final TtsJobLeaseService leases = mock(TtsJobLeaseService.class);
    private final TtsOutputFinalizationService uploads = mock(TtsOutputFinalizationService.class);
    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final WorkerDeliveryProperties config = properties();

    private static WorkerDeliveryProperties properties() {
        var props = new WorkerDeliveryProperties();
        props.setApiKey("piper-test-secret");
        props.setKokoroApiKey("kokoro-test-secret");
        return props;
    }

    private TtsJobWorkerV2LifecycleController controller() {
        return new TtsJobWorkerV2LifecycleController(
                new WorkerApiKeyVerifier(config), config, leases, uploads, jdbc);
    }

    @Test
    void foreignCredentialAndMissingIdentityCannotTouchLease() {
        UUID id = UUID.randomUUID();
        UUID token = UUID.randomUUID();
        var payload = new TtsJobWorkerV2LifecycleController.LeaseRequest("worker-1", token);
        assertThat(controller().heartbeat(id, null, payload).getStatusCode().value()).isEqualTo(401);
        assertThat(controller().heartbeat(id, "Bearer invalid", payload)
                .getStatusCode().value()).isEqualTo(401);
        verify(leases, never()).heartbeatForEngine(any(), any(), any(), any(), any());
    }

    @Test
    void kokoroLifecycleIsDisabledByDefault() {
        UUID id = UUID.randomUUID();
        var payload = new TtsJobWorkerV2LifecycleController.LeaseRequest("kokoro-1", UUID.randomUUID());
        assertThat(controller().heartbeat(id, "Bearer kokoro-test-secret", payload)
                .getStatusCode().value()).isEqualTo(503);
        verify(leases, never()).heartbeatForEngine(any(), any(), any(), any(), any());
    }

    @Test
    void piperIdentitySuppliesServerAuthenticatedEngine() {
        UUID id = UUID.randomUUID();
        UUID token = UUID.randomUUID();
        when(leases.heartbeatForEngine(any(), any(), any(), any(), any()))
                .thenReturn(Optional.empty());
        assertThat(controller().heartbeat(
                id, "Bearer piper-test-secret",
                new TtsJobWorkerV2LifecycleController.LeaseRequest("piper-1", token))
                .getStatusCode().value()).isEqualTo(409);
        verify(leases).heartbeatForEngine(
                id, "piper-1", token, TtsEngine.PIPER, config.getLeaseDuration());
    }

    @Test
    void kokoroCannotReportFailedJobWhenFeatureDisabled() {
        var req = new TtsJobWorkerV2LifecycleController.FailRequest(
                UUID.randomUUID(), "kokoro-1", UUID.randomUUID(), "MODEL_ERROR", "no file");
        assertThat(controller().fail(UUID.randomUUID(), "Bearer kokoro-test-secret", req)
                .getStatusCode().value()).isEqualTo(503);
        verify(leases, never()).failWorkerForEngine(any(), any(), any(), any(), any(), any(), any());
    }
}
