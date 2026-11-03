package io.github.alimbetov.voxprep.backend.learner.web;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentAccessPolicy;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerExactLocalizationService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerPremiumAccessDeniedException;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class LearnerExactLocalizationHttpTest {
    private final LearnerContentAccessPolicy access = mock(LearnerContentAccessPolicy.class);
    private final LearnerExactLocalizationService service = mock(LearnerExactLocalizationService.class);
    private static final String PATH = "/api/v1/content/phrase/HELLO/revisions/1/localizations/ru/revisions/2";

    @Test
    void serializesExactFlutterLocalizationWithoutFallbackFields() throws Exception {
        when(service.get("phrase", "HELLO", 1, "ru", 2)).thenReturn(
                new LearnerExactLocalizationService.ExactLocalization(
                        "HELLO", "phrase", 1, "ru", 2, "c".repeat(64),
                        null, null, null, "Привет", null, null));
        var mvc = MockMvcBuilders.standaloneSetup(
                new LearnerExactLocalizationController(access, service))
                .setControllerAdvice(new LearnerContentExceptionHandler()).build();
        mvc.perform(get(PATH))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.contentRevision").value(1))
                .andExpect(jsonPath("$.localizationRevision").value(2))
                .andExpect(jsonPath("$.checksum").value("c".repeat(64)))
                .andExpect(jsonPath("$.translation").value("Привет"));
    }

    @Test
    void premiumDeniedBefore304OrLocalizationRead() throws Exception {
        doThrow(new LearnerPremiumAccessDeniedException())
                .when(access).requireAccessible("phrase", "HELLO");
        var mvc = MockMvcBuilders.standaloneSetup(
                new LearnerExactLocalizationController(access, service))
                .setControllerAdvice(new LearnerContentExceptionHandler()).build();
        mvc.perform(get(PATH).header("If-None-Match", "*"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("PREMIUM_UNLOCK_REQUIRED"));
        verifyNoInteractions(service);
    }
}
