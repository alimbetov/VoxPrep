package io.github.alimbetov.voxprep.backend.installation.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import jakarta.servlet.http.HttpServletRequest;
import java.util.stream.Stream;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

class LearnerApiRoutePolicyTest {

    static Stream<String> protectedRoutes() {
        return Stream.of(
                "/api/v1/catalogue",
                "/api/v1/catalogue/",
                "/api/v1/assessments/practice-tests/PRACTICE_01",
                "/api/v1/content",
                "/api/v2/content/phrase/INTRO/external-video",
                "/api/v1/content/phrase/INTRO",
                "/api/v1/content/phrase/INTRO/localization",
                "/api/v1/content/phrase/INTRO/media",
                "/api/v1/content/phrase/INTRO/media/123/content",
                "/api/v1/content/phrase/INTRO/audio/123/content",
                "/api/v1/purchases",
                "/api/v1/purchases/verify",
                "/api/v1/media/asset",
                "/api/v1/catalogues/legacy",
                "/api/v1/assessment/legacy");
    }

    static Stream<String> nonLearnerRoutes() {
        return Stream.of(
                "/admin",
                "/admin/content",
                "/login",
                "/api/v1/installations",
                "/api/v1/catalogue-preview",
                "/api/v1/assessments-other",
                "/api/v1/content-public",
                "/api/v2/content-public",
                "/api/v1/purchases-public",
                "/api/v1/other");
    }

    @ParameterizedTest
    @MethodSource("protectedRoutes")
    void protectsKnownLearnerPaths(String path) {
        assertThat(LearnerApiRoutePolicy.isProtectedPath(path)).isTrue();
        HttpServletRequest request = mock(HttpServletRequest.class);
        when(request.getRequestURI()).thenReturn("/voxprep" + path);
        when(request.getContextPath()).thenReturn("/voxprep");
        assertThat(LearnerApiRoutePolicy.isProtected(request)).isTrue();
    }

    @ParameterizedTest
    @MethodSource("nonLearnerRoutes")
    void doesNotMatchOtherPathSegments(String path) {
        assertThat(LearnerApiRoutePolicy.isProtectedPath(path)).isFalse();
    }
}
