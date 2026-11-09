package io.github.alimbetov.voxprep.backend.installation.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import tools.jackson.databind.ObjectMapper;

@Component
public class InstallationAuthenticationFilter extends OncePerRequestFilter {

    private final InstallationAuthenticationService authenticationService;
    private final ObjectMapper objectMapper;

    public InstallationAuthenticationFilter(
            InstallationAuthenticationService authenticationService,
            ObjectMapper objectMapper) {
        this.authenticationService = authenticationService;
        this.objectMapper = objectMapper;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !LearnerApiRoutePolicy.isProtected(request);
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain) throws ServletException, IOException {
        try {
            var token = extractBearerToken(request.getHeader(HttpHeaders.AUTHORIZATION));
            var principal = authenticationService.authenticate(token);
            var authentication = UsernamePasswordAuthenticationToken.authenticated(
                    principal,
                    token,
                    List.of(new SimpleGrantedAuthority("ROLE_LEARNER")));
            // A loaded context may be shared with an admin HttpSession. Keep
            // bearer authentication request-local instead of mutating that object.
            var learnerContext = SecurityContextHolder.createEmptyContext();
            learnerContext.setAuthentication(authentication);
            SecurityContextHolder.setContext(learnerContext);
            filterChain.doFilter(request, response);
        } catch (InstallationAuthenticationException exception) {
            SecurityContextHolder.clearContext();
            writeError(response, request.getRequestURI(), exception);
        }
    }

    private static String extractBearerToken(String authorization) {
        if (authorization == null || authorization.isBlank()) {
            return null;
        }
        if (!authorization.startsWith("Bearer ")) {
            throw new InstallationAuthenticationException(
                    "INSTALLATION_TOKEN_INVALID",
                    "Authorization header must use Bearer scheme");
        }
        var token = authorization.substring(7).trim();
        if (token.isEmpty()) {
            throw new InstallationAuthenticationException(
                    "INSTALLATION_TOKEN_MISSING",
                    "Installation token is required");
        }
        return token;
    }

    private void writeError(
            HttpServletResponse response,
            String path,
            InstallationAuthenticationException exception) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        objectMapper.writeValue(response.getOutputStream(), Map.of(
                "timestamp", Instant.now().toString(),
                "status", HttpServletResponse.SC_UNAUTHORIZED,
                "code", exception.getCode(),
                "message", exception.getMessage(),
                "path", path));
    }
}
