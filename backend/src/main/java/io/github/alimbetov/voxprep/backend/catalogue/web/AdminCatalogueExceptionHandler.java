package io.github.alimbetov.voxprep.backend.catalogue.web;

import io.github.alimbetov.voxprep.backend.catalogue.application.CatalogueAuthoringConflictException;
import io.github.alimbetov.voxprep.backend.catalogue.application.CatalogueAuthoringNotFoundException;
import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice(assignableTypes = AdminCatalogueAuthoringController.class)
public class AdminCatalogueExceptionHandler {

    @ExceptionHandler(CatalogueAuthoringConflictException.class)
    ResponseEntity<Map<String, Object>> conflict(RuntimeException exception, HttpServletRequest request) {
        return error(HttpStatus.CONFLICT, "CATALOGUE_CONFLICT", exception.getMessage(), request);
    }

    @ExceptionHandler(CatalogueAuthoringNotFoundException.class)
    ResponseEntity<Map<String, Object>> notFound(RuntimeException exception, HttpServletRequest request) {
        return error(HttpStatus.NOT_FOUND, "CATALOGUE_NOT_FOUND", exception.getMessage(), request);
    }

    @ExceptionHandler({IllegalArgumentException.class, MethodArgumentNotValidException.class})
    ResponseEntity<Map<String, Object>> badRequest(Exception exception, HttpServletRequest request) {
        var message = exception instanceof MethodArgumentNotValidException validationException
                ? validationException.getBindingResult().getFieldError() == null
                    ? "Request validation failed"
                    : validationException.getBindingResult().getFieldError().getDefaultMessage()
                : exception.getMessage();
        return error(HttpStatus.BAD_REQUEST, "CATALOGUE_INVALID_REQUEST", message, request);
    }

    private static ResponseEntity<Map<String, Object>> error(
            HttpStatus status,
            String code,
            String message,
            HttpServletRequest request) {
        return ResponseEntity.status(status).body(Map.of(
                "timestamp", Instant.now().toString(),
                "status", status.value(),
                "code", code,
                "message", message == null ? status.getReasonPhrase() : message,
                "path", request.getRequestURI()));
    }
}
