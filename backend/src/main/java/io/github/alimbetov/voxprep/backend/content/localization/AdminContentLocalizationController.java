package io.github.alimbetov.voxprep.backend.content.localization;

import io.github.alimbetov.voxprep.backend.content.application.ContentAuthoringConflictException;
import io.github.alimbetov.voxprep.backend.content.application.ContentRevisionNotFoundException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.Pattern;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestController
@RequestMapping("/admin/api/v1/content/localizations")
public class AdminContentLocalizationController {

    private final ContentLocalizationAuthoringService service;

    public AdminContentLocalizationController(ContentLocalizationAuthoringService service) {
        this.service = service;
    }

    @GetMapping("/{id}")
    public ContentLocalizationAuthoringService.Snapshot get(@PathVariable UUID id) {
        return service.get(id);
    }

    @PostMapping
    public ContentLocalizationAuthoringService.Snapshot create(@Valid @RequestBody CreateRequest request) {
        return service.create(
                request.contentRevisionId(), request.locale(), null, request.fields());
    }

    @PutMapping("/{id}/draft")
    public ContentLocalizationAuthoringService.Snapshot updateDraft(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateRequest request) {
        return service.updateDraft(id, request.expectedVersion(), null, request.fields());
    }

    @PostMapping("/{id}/review")
    public ContentLocalizationAuthoringService.Snapshot review(
            @PathVariable UUID id,
            @Valid @RequestBody ReviewRequest request,
            Authentication authentication) {
        return service.submitForReview(
                id, request.expectedVersion(), authentication.getName(), request.reason(), request.comment());
    }

    @PostMapping("/{id}/approve")
    public ContentLocalizationAuthoringService.Snapshot approve(
            @PathVariable UUID id,
            @Valid @RequestBody ReviewRequest request,
            Authentication authentication) {
        return service.approve(
                id, request.expectedVersion(), authentication.getName(), request.reason(), request.comment());
    }

    @PostMapping("/{id}/next")
    public ContentLocalizationAuthoringService.Snapshot next(
            @PathVariable UUID id,
            @Valid @RequestBody VersionRequest request) {
        return service.createNext(id, request.expectedVersion());
    }

    public record CreateRequest(
            @NotNull UUID contentRevisionId,
            @NotBlank @Size(max = 64) @Pattern(regexp = "[A-Za-z]{2,8}(-[A-Za-z0-9]{1,8})*") String locale,
            String checksumSha256,
            @Size(max = 256) String title,
            @Size(max = 512) String subtitle,
            @Size(max = 4096) String description,
            String translation,
            String hint,
            String explanation) {
        ContentLocalizationAuthoringService.Fields fields() {
            return new ContentLocalizationAuthoringService.Fields(
                    title, subtitle, description, translation, hint, explanation);
        }
    }

    public record UpdateRequest(
            @Min(0) long expectedVersion,
            String checksumSha256,
            @Size(max = 256) String title,
            @Size(max = 512) String subtitle,
            @Size(max = 4096) String description,
            String translation,
            String hint,
            String explanation) {
        ContentLocalizationAuthoringService.Fields fields() {
            return new ContentLocalizationAuthoringService.Fields(
                    title, subtitle, description, translation, hint, explanation);
        }
    }

    public record ReviewRequest(
            @Min(0) long expectedVersion,
            @Size(max = 512) String reason,
            @Size(max = 2048) String comment) {
    }

    public record VersionRequest(@Min(0) long expectedVersion) {
    }
}

@RestControllerAdvice(assignableTypes = AdminContentLocalizationController.class)
class AdminContentLocalizationExceptionHandler {

    @ExceptionHandler({ContentAuthoringConflictException.class, IllegalStateException.class})
    ResponseEntity<Map<String, Object>> conflict(RuntimeException exception, HttpServletRequest request) {
        return error(HttpStatus.CONFLICT, "CONTENT_LOCALIZATION_CONFLICT", exception.getMessage(), request);
    }

    @ExceptionHandler({ContentLocalizationNotFoundException.class, ContentRevisionNotFoundException.class})
    ResponseEntity<Map<String, Object>> notFound(RuntimeException exception, HttpServletRequest request) {
        return error(HttpStatus.NOT_FOUND, "CONTENT_LOCALIZATION_NOT_FOUND", exception.getMessage(), request);
    }

    @ExceptionHandler({IllegalArgumentException.class, MethodArgumentNotValidException.class})
    ResponseEntity<Map<String, Object>> badRequest(Exception exception, HttpServletRequest request) {
        String message = exception instanceof MethodArgumentNotValidException validationException
                ? validationException.getBindingResult().getFieldError() == null
                    ? "Request validation failed"
                    : validationException.getBindingResult().getFieldError().getDefaultMessage()
                : exception.getMessage();
        return error(HttpStatus.BAD_REQUEST, "CONTENT_LOCALIZATION_INVALID_REQUEST", message, request);
    }

    private static ResponseEntity<Map<String, Object>> error(
            HttpStatus status, String code, String message, HttpServletRequest request) {
        return ResponseEntity.status(status).body(Map.of(
                "timestamp", Instant.now().toString(),
                "status", status.value(),
                "code", code,
                "message", message == null ? status.getReasonPhrase() : message,
                "path", request.getRequestURI()));
    }
}
