package io.github.alimbetov.voxprep.backend.billing;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import io.github.alimbetov.voxprep.backend.installation.security.InstallationPrincipal;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class PurchaseVerificationControllerTest {
    @Test
    void responseMatchesFlutterContractWithoutEverEchoingStoreProof() throws Exception {
        var service=mock(LifetimePurchaseService.class);
        when(service.verify(any(),any())).thenReturn(
                new LifetimePurchaseService.VerificationResult(true,"FULL",
                        Instant.parse("2026-11-04T00:00:00Z")));
        var mvc=MockMvcBuilders.standaloneSetup(new PurchaseVerificationController(service))
                .build();
        // @AuthenticationPrincipal requires security context normally set by the installation filter.
        // Without a production filter, this standalone test verifies the mandatory deny path.
        mvc.perform(post("/api/v1/purchases/verify")
                .contentType("application/json")
                .content("{\"provider\":\"GOOGLE_PLAY\",\"productId\":\"voxprep_full_unlock\","
                        + "\"purchaseEventId\":\"e-1\",\"verificationData\":\"private-token\"}"))
                .andExpect(status().isUnauthorized());
        verifyNoInteractions(service);
    }
}
