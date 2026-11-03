package io.github.alimbetov.voxprep.backend.asset.web;

import io.github.alimbetov.voxprep.backend.asset.application.LearnerMediaService;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Arrays;
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
@RequestMapping("/api/v1/media/assets")
public class LearnerMediaController {

    private static final String CACHE_CONTROL = "private, max-age=31536000, immutable";

    private final LearnerMediaService service;

    public LearnerMediaController(LearnerMediaService service) {
        this.service = service;
    }

    @GetMapping("/{assetId}/content")
    public ResponseEntity<byte[]> content(
            @PathVariable UUID assetId,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        LearnerMediaService.MediaDescriptor descriptor = service.describe(assetId);
        if (matches(ifNoneMatch, descriptor.etag())) {
            return ResponseEntity.status(HttpStatus.NOT_MODIFIED)
                    .header(HttpHeaders.ETAG, descriptor.etag())
                    .header(HttpHeaders.CACHE_CONTROL, CACHE_CONTROL)
                    .build();
        }

        LearnerMediaService.MediaContent content = service.read(descriptor);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(content.mediaType()))
                .contentLength(descriptor.sizeBytes())
                .header(HttpHeaders.ETAG, descriptor.etag())
                .header(HttpHeaders.CACHE_CONTROL, CACHE_CONTROL)
                .header("X-Content-Type-Options", "nosniff")
                .body(content.bytes());
    }

    @ExceptionHandler({
            LearnerMediaService.MediaUnavailableException.class,
            LearnerMediaService.MediaIntegrityException.class
    })
    public ResponseEntity<Void> unavailable(RuntimeException exception, HttpServletRequest request) {
        return ResponseEntity.notFound().build();
    }

    static boolean matches(String ifNoneMatch, String currentEtag) {
        if (ifNoneMatch == null || ifNoneMatch.isBlank()) {
            return false;
        }
        return Arrays.stream(ifNoneMatch.split(","))
                .map(String::trim)
                .anyMatch(candidate -> "*".equals(candidate)
                        || weakValue(candidate).equals(weakValue(currentEtag)));
    }

    private static String weakValue(String etag) {
        String value = etag == null ? "" : etag.trim();
        if (value.startsWith("W/")) {
            value = value.substring(2).trim();
        }
        return value;
    }
}
