package io.github.alimbetov.voxprep.backend.installation.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.stream.Stream;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import tools.jackson.databind.ObjectMapper;

class InstallationAuthenticationFilterRouteTest {

    static Stream<String> protectedRequests() {
        return Stream.of(
                "/api/v1/catalogue",
                "/api/v1/assessments/practice-tests/TEST",
                "/api/v1/content/phrase/TEST",
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
}
