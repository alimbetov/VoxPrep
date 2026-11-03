package io.github.alimbetov.voxprep.backend.asset.web;

import io.github.alimbetov.voxprep.backend.asset.application.LearnerMediaService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentNotFoundException;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerPublishedMediaService;
import io.github.alimbetov.voxprep.backend.learner.web.LearnerHttpCache;
import jakarta.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/content")
public class LearnerMediaController {

    private final LearnerPublishedMediaService service;

    public LearnerMediaController(LearnerPublishedMediaService service) {
        this.service = service;
    }

    @GetMapping("/{contentType}/{contentCode}/audio")
    public List<LearnerPublishedMediaService.AudioAssetSnapshot> audio(
            @PathVariable String contentType,
            @PathVariable String contentCode) {
        return service.listAudio(contentType, contentCode);
    }

    @GetMapping("/{contentType}/{contentCode}/audio/{assetId}/content")
    public ResponseEntity<byte[]> content(
            @PathVariable String contentType,
            @PathVariable String contentCode,
            @PathVariable UUID assetId,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        LearnerMediaService.MediaDescriptor descriptor = service.requireAudio(contentType, contentCode, assetId);
        if (matches(ifNoneMatch, descriptor.etag())) {
            return ResponseEntity.status(HttpStatus.NOT_MODIFIED)
                    .header(HttpHeaders.ETAG, descriptor.etag())
                    .header(HttpHeaders.CACHE_CONTROL, LearnerHttpCache.CACHE_CONTROL)
                    .build();
        }

        LearnerMediaService.MediaContent content = service.read(descriptor);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(content.mediaType()))
                .contentLength(descriptor.sizeBytes())
                .header(HttpHeaders.ETAG, descriptor.etag())
                .header(HttpHeaders.CACHE_CONTROL, LearnerHttpCache.CACHE_CONTROL)
                .header("X-Content-Type-Options", "nosniff")
                .body(content.bytes());
    }

    @ExceptionHandler({
            LearnerMediaService.MediaUnavailableException.class,
            LearnerMediaService.MediaIntegrityException.class,
            LearnerContentNotFoundException.class
    })
    public ResponseEntity<Void> unavailable(RuntimeException exception, HttpServletRequest request) {
        return ResponseEntity.notFound().build();
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Void> invalid(RuntimeException exception, HttpServletRequest request) {
        return ResponseEntity.badRequest().build();
    }

    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<Void> inconsistent(RuntimeException exception, HttpServletRequest request) {
        return ResponseEntity.status(HttpStatus.CONFLICT).build();
    }

    static boolean matches(String ifNoneMatch, String currentEtag) {
        return LearnerHttpCache.matches(ifNoneMatch, currentEtag);
    }
}
