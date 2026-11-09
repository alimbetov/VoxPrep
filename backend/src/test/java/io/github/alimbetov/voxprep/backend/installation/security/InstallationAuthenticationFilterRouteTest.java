package io.github.alimbetov.voxprep.backend.installation.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.stream.Stream;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicBoolean;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import tools.jackson.databind.ObjectMapper;

class InstallationAuthenticationFilterRouteTest {

    static Stream<String> protectedRequests() {
        return Stream.of(
                "/api/v1/catalogue",
                "/api/v1/assessments/practice-tests/TEST",
                "/api/v1/content/phrase/TEST",
                "/api/v2/content/vocabulary/TEST/external-video",
                "/api/v1/content/phrase/TEST/localization",
                "/api/v1/content/phrase/TEST/media",
                "/api/v1/purchases/verify");
    }

    @ParameterizedTest
    @MethodSource("protectedRequests")
    void missingInstallationTokenIsRejectedBeforeController(String path) throws Exception {
        InstallationAuthenticationService service = mock(InstallationAuthenticationService.class);
        when(service.authenticate(isNull())).thenThrow(
                new InstallationAuthenticationException("INSTALLATION_TOKEN_MISSING", "Installation token is required"));
        var filter = new InstallationAuthenticationFilter(service, mock(ObjectMapper.class));
        var request = new MockHttpServletRequest("GET", path);
        var response = new MockHttpServletResponse();
        var chain = new MockFilterChain();

        filter.doFilter(request, response, chain);

        assertThat(response.getStatus()).isEqualTo(401);
        assertThat(chain.getRequest()).isNull();
        verify(service).authenticate(null);
    }

    @ParameterizedTest
    @ValueSource(booleans = {false, true})
    void bearerRequestDoesNotOverwriteLoadedAdminSessionContext(boolean downstreamFails) throws Exception {
        var service = mock(InstallationAuthenticationService.class);
        var principal = new InstallationPrincipal(UUID.randomUUID());
        when(service.authenticate("test-token")).thenReturn(principal);
        var filter = new InstallationAuthenticationFilter(service, mock(ObjectMapper.class));
        var request = new MockHttpServletRequest("GET", "/api/v2/content/vocabulary/TEST/external-video");
        request.addHeader("Authorization", "Bearer test-token");
        var sharedSessionContext = SecurityContextHolder.createEmptyContext();
        var admin = UsernamePasswordAuthenticationToken.authenticated("editor", "unused",
                List.of(new SimpleGrantedAuthority("ROLE_ADMIN")));
        sharedSessionContext.setAuthentication(admin);
        SecurityContextHolder.setContext(sharedSessionContext);
        var invoked = new AtomicBoolean();
        FilterChain chain = (req, res) -> {
            invoked.set(true);
            var learner = SecurityContextHolder.getContext().getAuthentication();
            assertThat(learner.getPrincipal()).isEqualTo(principal);
            assertThat(learner.getAuthorities()).extracting(GrantedAuthority::getAuthority)
                    .containsExactly("ROLE_LEARNER");
            if (downstreamFails) throw new ServletException("Controller failure");
        };
        try {
            var response = new MockHttpServletResponse();
            if (downstreamFails) {
                assertThatThrownBy(() -> filter.doFilter(request, response, chain))
                        .isInstanceOf(ServletException.class);
            } else {
                filter.doFilter(request, response, chain);
            }
            assertThat(invoked).isTrue();
            assertThat(sharedSessionContext.getAuthentication()).isSameAs(admin);
        } finally {
            SecurityContextHolder.clearContext();
        }
    }
}
