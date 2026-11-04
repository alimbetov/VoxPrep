package io.github.alimbetov.voxprep.backend.learner.web;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import io.github.alimbetov.voxprep.backend.asset.web.LearnerMediaController;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerAssessmentService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentAccessPolicy;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerLocalizationService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerPremiumAccessDeniedException;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerPublishedMediaService;
import java.util.stream.Stream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class LearnerPremiumHttpBoundaryTest {

    private final LearnerContentService content = mock(LearnerContentService.class);
    private final LearnerLocalizationService localization = mock(LearnerLocalizationService.class);
    private final LearnerAssessmentService assessment = mock(LearnerAssessmentService.class);
    private final LearnerPublishedMediaService media = mock(LearnerPublishedMediaService.class);
    private final LearnerContentAccessPolicy accessPolicy = mock(LearnerContentAccessPolicy.class);
    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        mvc = MockMvcBuilders.standaloneSetup(
                        new LearnerContentController(content, localization, accessPolicy),
                        new LearnerAssessmentController(assessment, accessPolicy),
                        new LearnerMediaController(media, accessPolicy))
                .setControllerAdvice(new LearnerContentExceptionHandler())
                .build();
    }

    static Stream<Arguments> protectedPayloadRoutes() {
        String asset = "11111111-1111-4111-8111-111111111111";
        return Stream.of(
                Arguments.of("/api/v1/content/phrase/LOCKED", "phrase", "LOCKED"),
                Arguments.of("/api/v1/content/phrase/LOCKED/localization?locale=en", "phrase", "LOCKED"),
                Arguments.of("/api/v1/content/phrase/LOCKED/media", "phrase", "LOCKED"),
                Arguments.of("/api/v1/content/phrase/LOCKED/audio", "phrase", "LOCKED"),
                Arguments.of("/api/v1/content/phrase/LOCKED/media/" + asset + "/content", "phrase", "LOCKED"),
                Arguments.of("/api/v1/content/phrase/LOCKED/audio/" + asset + "/content", "phrase", "LOCKED"),
                Arguments.of("/api/v1/assessments/practice-tests/LOCKED", "practice_test", "LOCKED"));
    }

    @ParameterizedTest
    @MethodSource("protectedPayloadRoutes")
    void premiumPayloadIsDeniedBeforeBusinessReadEvenWithMatchingCacheTag(
            String url, String type, String code) throws Exception {
        doThrow(new LearnerPremiumAccessDeniedException())
                .when(accessPolicy).requireAccessible(type, code);

        mvc.perform(get(url).header("If-None-Match", "*"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("PREMIUM_UNLOCK_REQUIRED"));

        verifyNoInteractions(content, localization, assessment, media);
    }
}
