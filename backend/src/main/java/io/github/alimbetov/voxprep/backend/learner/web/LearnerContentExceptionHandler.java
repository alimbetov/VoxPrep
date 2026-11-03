package io.github.alimbetov.voxprep.backend.learner.web;

import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentNotFoundException;
import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice(assignableTypes = LearnerContentController.class)
public class LearnerContentExceptionHandler {

    @ExceptionHandler(LearnerContentNotFoundException.class)
    ResponseEntity<Map<String, Object>> notFound(RuntimeException exception, HttpServletRequest request) {
        return error(HttpStatus.NOT_FOUND, "LEARNER_CONTENT_NOT_FOUND", exception.getMessage(), request);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    ResponseEntity<Map<String, Object>> badRequest(RuntimeException exception, HttpServletRequest request) {
        return error(HttpStatus.BAD_REQUEST, "LEARNER_CONTENT_INVALID_REQUEST", exception.getMessage(), request);
    }

    @ExceptionHandler(IllegalStateException.class)
    ResponseEntity<Map<String, Object>> conflict(RuntimeException exception, HttpServletRequest request) {
        return error(HttpStatus.CONFLICT, "LEARNER_PUBLICATION_INCONSISTENT", exception.getMessage(), request);
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
