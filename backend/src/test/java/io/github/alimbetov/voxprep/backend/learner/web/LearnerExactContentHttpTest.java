package io.github.alimbetov.voxprep.backend.learner.web;

import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentAccessPolicy;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerExactContentPayloadService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerPremiumAccessDeniedException;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class LearnerExactContentHttpTest {
    private final LearnerContentAccessPolicy access = mock(LearnerContentAccessPolicy.class);
    private final LearnerExactContentPayloadService service = mock(LearnerExactContentPayloadService.class);

    @Test
    void serializesFlutterExactPayload() throws Exception {
        when(service.get("phrase", "HELLO", 2)).thenReturn(new LearnerExactContentPayloadService.ExactPayload(
                "HELLO", "phrase", 2, "b".repeat(64), "Title", "Subtitle", "Description",
                "CATEGORY", "CATEGORY", "LEVEL", "LEVEL", 5, false, List.of("LISTENING"),
                Map.of("kind", "phrase", "phrase", "Hello", "usage", "Greeting",
                        "examples", List.of("Hi"))));
        var mvc = MockMvcBuilders.standaloneSetup(new LearnerExactContentController(access, service))
                .setControllerAdvice(new LearnerContentExceptionHandler()).build();

        mvc.perform(get("/api/v1/content/phrase/HELLO/revisions/2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.revision").value(2))
                .andExpect(jsonPath("$.checksum").value("b".repeat(64)))
                .andExpect(jsonPath("$.body.kind").value("phrase"))
                .andExpect(jsonPath("$.categoryLabel").value("CATEGORY"))
                .andExpect(jsonPath("$.hasAudio").value(false));
    }

    @Test
    void forbidsPremiumBeforePayloadOrEtag304() throws Exception {
        doThrow(new LearnerPremiumAccessDeniedException())
                .when(access).requireAccessible("phrase", "HELLO");
        var mvc = MockMvcBuilders.standaloneSetup(new LearnerExactContentController(access, service))
                .setControllerAdvice(new LearnerContentExceptionHandler()).build();

        mvc.perform(get("/api/v1/content/phrase/HELLO/revisions/2").header("If-None-Match", "*"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("PREMIUM_UNLOCK_REQUIRED"));
        verifyNoInteractions(service);
    }
}
