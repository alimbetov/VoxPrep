package io.github.alimbetov.voxprep.backend.learner.web;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentAccessPolicy;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerExactPracticeTestService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerPremiumAccessDeniedException;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class LearnerExactPracticeTestControllerTest {
    private final LearnerContentAccessPolicy access = mock(LearnerContentAccessPolicy.class);
    private final LearnerExactPracticeTestService service = mock(LearnerExactPracticeTestService.class);
    private static final String PATH = "/api/v1/assessment/practice-tests/TEST_01/revisions/2";

    @Test
    void serializesExactStrictFlutterPracticeTestDto() throws Exception {
        when(service.get("TEST_01", 2)).thenReturn(
                new LearnerExactPracticeTestService.ExactPracticeTest(
                        "TEST_01", 2, "b".repeat(64), "Interview", "Java",
                        "exam", 8500, List.of(new LearnerExactPracticeTestService.QuestionRef(
                                0, new LearnerExactPracticeTestService.QuestionIdentity(
                                        "Q_01", 1, "c".repeat(64)), 3))));
        var mvc = MockMvcBuilders.standaloneSetup(new LearnerExactPracticeTestController(access, service))
                .setControllerAdvice(new LearnerContentExceptionHandler()).build();

        mvc.perform(get(PATH))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.practiceTestCode").value("TEST_01"))
                .andExpect(jsonPath("$.revision").value(2))
                .andExpect(jsonPath("$.mode").value("exam"))
                .andExpect(jsonPath("$.passingScoreBasisPoints").value(8500))
                .andExpect(jsonPath("$.questionRefs[0].order").value(0))
                .andExpect(jsonPath("$.questionRefs[0].points").value(3))
                .andExpect(jsonPath("$.questionRefs[0].question.questionCode").value("Q_01"));
    }

    @Test
    void deniesPremiumBeforeReadingOr304() throws Exception {
        doThrow(new LearnerPremiumAccessDeniedException())
                .when(access).requireAccessible("practice_test", "TEST_01");
        var mvc = MockMvcBuilders.standaloneSetup(new LearnerExactPracticeTestController(access, service))
                .setControllerAdvice(new LearnerContentExceptionHandler()).build();
        mvc.perform(get(PATH).header("If-None-Match", "*"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("PREMIUM_UNLOCK_REQUIRED"));
        verifyNoInteractions(service);
    }
}
