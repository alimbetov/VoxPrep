package io.github.alimbetov.voxprep.backend.learner.web;

import io.github.alimbetov.voxprep.backend.asset.application.LearnerMediaService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerAssetResolutionService;
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
public class LearnerAssetDownloadController {

    private final LearnerAssetResolutionService resolution;
    private final LearnerMediaService media;

    public LearnerAssetDownloadController(
            LearnerAssetResolutionService resolution,
            LearnerMediaService media) {
        this.resolution = resolution;
        this.media = media;
    }

    @GetMapping("/{assetId}/content")
    public ResponseEntity<byte[]> content(
            @PathVariable UUID assetId,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        var descriptor = resolution.requirePublished(assetId);
        if (LearnerHttpCache.matches(ifNoneMatch, descriptor.etag())) {
            return ResponseEntity.status(HttpStatus.NOT_MODIFIED)
                    .header(HttpHeaders.ETAG, descriptor.etag())
                    .header(HttpHeaders.CACHE_CONTROL, LearnerHttpCache.CACHE_CONTROL)
                    .build();
        }
        var bytes = media.read(descriptor);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(bytes.mediaType()))
                .contentLength(descriptor.sizeBytes())
                .header(HttpHeaders.ETAG, descriptor.etag())
                .header(HttpHeaders.CACHE_CONTROL, LearnerHttpCache.CACHE_CONTROL)
                .header("X-Content-Type-Options", "nosniff")
                .body(bytes.bytes());
    }

    @ExceptionHandler({
            LearnerMediaService.MediaUnavailableException.class,
            LearnerMediaService.MediaIntegrityException.class
    })
    public ResponseEntity<Void> unavailable(RuntimeException ignored) {
        return ResponseEntity.notFound().build();
    }
}
