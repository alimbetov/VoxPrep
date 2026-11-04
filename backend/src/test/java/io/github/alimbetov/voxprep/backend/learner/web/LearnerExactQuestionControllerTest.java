package io.github.alimbetov.voxprep.backend.learner.web;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import io.github.alimbetov.voxprep.backend.learner.application.LearnerExactQuestionService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerPremiumAccessDeniedException;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class LearnerExactQuestionControllerTest {
    private final LearnerExactQuestionService service = mock(LearnerExactQuestionService.class);

    @Test
    void serializesStrictFlutterQuestionDto() throws Exception {
        when(service.get("Q_01", 2)).thenReturn(new LearnerExactQuestionService.QuestionPayload(
                "Q_01", 2, "c".repeat(64),
                new LearnerExactQuestionService.SingleChoiceBody(
                        "singleChoice", "Which answer?", List.of("First", "Second"),
                        1, "GRAMMAR", "Reason.")));
        var mvc = MockMvcBuilders.standaloneSetup(new LearnerExactQuestionController(service))
                .setControllerAdvice(new LearnerContentExceptionHandler()).build();
        mvc.perform(get("/api/v1/assessment/questions/Q_01/revisions/2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.questionCode").value("Q_01"))
                .andExpect(jsonPath("$.revision").value(2))
                .andExpect(jsonPath("$.body.kind").value("singleChoice"))
                .andExpect(jsonPath("$.body.correctOptionIndex").value(1))
                .andExpect(jsonPath("$.body.options.length()").value(2))
                .andExpect(jsonPath("$.body.skillCode").value("GRAMMAR"));
    }

    @Test
    void premiumFailureCannotReturn304() throws Exception {
        when(service.get("Q_01", 2)).thenThrow(new LearnerPremiumAccessDeniedException());
        var mvc = MockMvcBuilders.standaloneSetup(new LearnerExactQuestionController(service))
                .setControllerAdvice(new LearnerContentExceptionHandler()).build();
        mvc.perform(get("/api/v1/assessment/questions/Q_01/revisions/2")
                        .header("If-None-Match", "*"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("PREMIUM_UNLOCK_REQUIRED"));
    }
}
