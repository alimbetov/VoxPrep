package io.github.alimbetov.voxprep.backend.asset.web;

import io.github.alimbetov.voxprep.backend.asset.application.LearnerMediaService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentNotFoundException;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerPublishedMediaService;
import io.github.alimbetov.voxprep.backend.learner.web.LearnerHttpCache;
import jakarta.servlet.http.HttpServletRequest;
import java.util.ArrayList;
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

    @GetMapping("/{contentType}/{contentCode}/media")
    public ResponseEntity<List<LearnerPublishedMediaService.MediaAssetSnapshot>> media(
            @PathVariable String contentType,
            @PathVariable String contentCode,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        List<LearnerPublishedMediaService.MediaAssetSnapshot> media = service.listMedia(contentType, contentCode);
        String etag = mediaListEtag(contentType, contentCode, media);
        return LearnerHttpCache.revalidate(media, etag, ifNoneMatch);
    }

    @GetMapping("/{contentType}/{contentCode}/media/{assetId}/content")
    public ResponseEntity<byte[]> mediaContent(
            @PathVariable String contentType,
            @PathVariable String contentCode,
            @PathVariable UUID assetId,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        LearnerMediaService.MediaDescriptor descriptor = service.requireMedia(contentType, contentCode, assetId);
        return contentResponse(descriptor, ifNoneMatch);
    }

    @GetMapping("/{contentType}/{contentCode}/audio")
    public ResponseEntity<List<LearnerPublishedMediaService.AudioAssetSnapshot>> audio(
            @PathVariable String contentType,
            @PathVariable String contentCode,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        List<LearnerPublishedMediaService.AudioAssetSnapshot> audio = service.listAudio(contentType, contentCode);
        String etag = audioListEtag(contentType, contentCode, audio);
        return LearnerHttpCache.revalidate(audio, etag, ifNoneMatch);
    }

    @GetMapping("/{contentType}/{contentCode}/audio/{assetId}/content")
    public ResponseEntity<byte[]> audioContent(
            @PathVariable String contentType,
            @PathVariable String contentCode,
            @PathVariable UUID assetId,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        LearnerMediaService.MediaDescriptor descriptor = service.requireAudio(contentType, contentCode, assetId);
        return contentResponse(descriptor, ifNoneMatch);
    }

    private ResponseEntity<byte[]> contentResponse(
            LearnerMediaService.MediaDescriptor descriptor,
            String ifNoneMatch) {
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

    static String mediaListEtag(
            String contentType,
            String contentCode,
            List<LearnerPublishedMediaService.MediaAssetSnapshot> media) {
        List<Object> components = new ArrayList<>();
        components.add(contentType);
        components.add(contentCode);
        for (LearnerPublishedMediaService.MediaAssetSnapshot item : media) {
            components.add(item.assetId());
            components.add(item.role());
            components.add(item.kind());
            components.add(item.mediaType());
            components.add(item.sizeBytes());
            components.add(item.sha256());
        }
        return LearnerHttpCache.weakEtag("media-list", components.toArray());
    }

    static String audioListEtag(
            String contentType,
            String contentCode,
            List<LearnerPublishedMediaService.AudioAssetSnapshot> audio) {
        List<Object> components = new ArrayList<>();
        components.add(contentType);
        components.add(contentCode);
        for (LearnerPublishedMediaService.AudioAssetSnapshot item : audio) {
            components.add(item.assetId());
            components.add(item.audioRole());
            components.add(item.language());
            components.add(item.mediaType());
            components.add(item.sizeBytes());
            components.add(item.sha256());
        }
        return LearnerHttpCache.weakEtag("audio-list", components.toArray());
    }
}
