package io.github.alimbetov.voxprep.backend.installation.security;

import jakarta.servlet.http.HttpServletRequest;
import java.util.List;

/**
 * One source of truth for installation-authenticated learner API paths.
 *
 * <p>Match a complete path segment, not an arbitrary string prefix, so
 * /api/v1/content-other is not accidentally classified as /api/v1/content.
 */
public final class LearnerApiRoutePolicy {

    private static final List<String> PROTECTED_ROOTS = List.of(
            "/api/v1/content",
            "/api/v1/catalogue",
            "/api/v1/catalogues",
            "/api/v1/assessment",
            "/api/v1/assessments",
            "/api/v1/media",
            "/api/v1/purchases");

    private LearnerApiRoutePolicy() {
    }

    public static boolean isProtected(HttpServletRequest request) {
        return isProtectedPath(request.getRequestURI().substring(request.getContextPath().length()));
    }

    public static boolean isProtectedPath(String path) {
        if (path == null) {
            return false;
        }
        return PROTECTED_ROOTS.stream()
                .anyMatch(root -> path.equals(root) || path.startsWith(root + "/"));
    }
}
