package io.github.alimbetov.voxprep.backend.learner.web;

import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentNotFoundException;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerPremiumAccessDeniedException;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerWireSnapshotUnavailableException;
import io.github.alimbetov.voxprep.backend.asset.web.LearnerMediaController;
import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice(assignableTypes = {
    LearnerContentController.class,
    LearnerExternalVideoController.class,
    LearnerExactContentController.class,
    LearnerExactLocalizationController.class,
    LearnerWireManifestController.class,
    LearnerAssetDownloadController.class,
    LearnerAssessmentController.class,
    LearnerExactQuestionController.class,
    LearnerExactPracticeTestController.class,
    LearnerMediaController.class
})
public class LearnerContentExceptionHandler {

    @ExceptionHandler(LearnerContentNotFoundException.class)
    ResponseEntity<Map<String, Object>> notFound(RuntimeException exception, HttpServletRequest request) {
        return error(HttpStatus.NOT_FOUND, "LEARNER_CONTENT_NOT_FOUND", exception.getMessage(), request);
    }

    @ExceptionHandler(LearnerPremiumAccessDeniedException.class)
    ResponseEntity<Map<String, Object>> premiumLocked(RuntimeException exception, HttpServletRequest request) {
        return error(HttpStatus.FORBIDDEN, "PREMIUM_UNLOCK_REQUIRED", "Lifetime unlock is required", request);
    }

    @ExceptionHandler(LearnerWireSnapshotUnavailableException.class)
    ResponseEntity<Map<String, Object>> snapshotUnavailable(RuntimeException exception, HttpServletRequest request) {
        return error(HttpStatus.SERVICE_UNAVAILABLE, "LEARNER_WIRE_SNAPSHOT_UNAVAILABLE",
                "Current publication has no verified Flutter wire snapshot", request);
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
