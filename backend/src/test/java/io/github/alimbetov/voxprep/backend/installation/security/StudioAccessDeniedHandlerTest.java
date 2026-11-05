package io.github.alimbetov.voxprep.backend.installation.security;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.web.csrf.MissingCsrfTokenException;

class StudioAccessDeniedHandlerTest {
    @Test
    void expiredFormKeeps403AndOffersRecoveryWithoutReflectingSecrets() throws Exception {
        var response = new MockHttpServletResponse();
        new StudioAccessDeniedHandler().handle(new MockHttpServletRequest(), response,
                new MissingCsrfTokenException("secret-token"));
        assertThat(response.getStatus()).isEqualTo(403);
        assertThat(response.getHeader("Cache-Control")).isEqualTo("no-store");
        assertThat(response.getContentAsString()).contains("This form has expired", "Your changes were not saved",
                "href=\"/admin\"", "href=\"/login\"").doesNotContain("secret-token", "Whitelabel");
    }

    @Test
    void realPermissionDenialIsNotMisrepresentedAsExpiredForm() throws Exception {
        var response = new MockHttpServletResponse();
        new StudioAccessDeniedHandler().handle(new MockHttpServletRequest(), response,
                new AccessDeniedException("internal permission details"));
        assertThat(response.getStatus()).isEqualTo(403);
        assertThat(response.getContentAsString()).contains("Access denied")
                .doesNotContain("form has expired", "internal permission details");
    }
}
