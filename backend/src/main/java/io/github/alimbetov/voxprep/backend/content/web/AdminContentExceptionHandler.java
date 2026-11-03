package io.github.alimbetov.voxprep.backend.content.web;

import io.github.alimbetov.voxprep.backend.content.application.ContentAuthoringConflictException;
import io.github.alimbetov.voxprep.backend.content.application.ContentRevisionNotFoundException;
import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice(assignableTypes = AdminContentAuthoringController.class)
public class AdminContentExceptionHandler {

    @ExceptionHandler({ContentAuthoringConflictException.class, IllegalStateException.class})
    ResponseEntity<Map<String, Object>> conflict(RuntimeException exception, HttpServletRequest request) {
        return error(HttpStatus.CONFLICT, "CONTENT_REVISION_CONFLICT", exception.getMessage(), request);
    }

    @ExceptionHandler(ContentRevisionNotFoundException.class)
    ResponseEntity<Map<String, Object>> notFound(
            ContentRevisionNotFoundException exception,
            HttpServletRequest request) {
        return error(HttpStatus.NOT_FOUND, "CONTENT_REVISION_NOT_FOUND", exception.getMessage(), request);
    }

    @ExceptionHandler({IllegalArgumentException.class, MethodArgumentNotValidException.class})
    ResponseEntity<Map<String, Object>> badRequest(Exception exception, HttpServletRequest request) {
        return error(HttpStatus.BAD_REQUEST, "CONTENT_AUTHORING_INVALID_REQUEST", message(exception), request);
    }

    private static String message(Exception exception) {
        if (exception instanceof MethodArgumentNotValidException validationException) {
            var fieldError = validationException.getBindingResult().getFieldError();
            return fieldError == null ? "Request validation failed" : fieldError.getDefaultMessage();
        }
        return exception.getMessage();
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
