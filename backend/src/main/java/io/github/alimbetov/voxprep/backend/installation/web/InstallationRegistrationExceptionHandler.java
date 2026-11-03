package io.github.alimbetov.voxprep.backend.installation.web;

import io.github.alimbetov.voxprep.backend.installation.security.InstallationAuthenticationException;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Map;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/** No token or installation existence details in registration failure responses. */
@RestControllerAdvice(assignableTypes = InstallationRegistrationController.class)
public class InstallationRegistrationExceptionHandler {

    @ExceptionHandler(InstallationAuthenticationException.class)
    public ResponseEntity<Map<String, Object>> unauthorized(
            InstallationAuthenticationException exception, HttpServletRequest request) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .cacheControl(CacheControl.noStore())
                .body(Map.of(
                        "status", HttpStatus.UNAUTHORIZED.value(),
                        "code", "INSTALLATION_ROTATION_NOT_AUTHORIZED",
                        "message", "Installation credential is invalid or missing",
                        "path", request.getRequestURI()));
    }
}
