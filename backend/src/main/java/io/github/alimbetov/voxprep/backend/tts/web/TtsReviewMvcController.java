package io.github.alimbetov.voxprep.backend.tts.web;

import io.github.alimbetov.voxprep.backend.asset.application.LearnerMediaService;
import io.github.alimbetov.voxprep.backend.content.web.AdminContentStudioMvc;
import io.github.alimbetov.voxprep.backend.tts.application.TtsReviewQueryService;
import java.util.UUID;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;

/** Browser-facing admin MP3 preview, never a RustFS URL. */
@AdminContentStudioMvc
@Controller
@RequestMapping("/admin/content/revisions/{revisionId}/tts")
public class TtsReviewMvcController {
    private final TtsReviewQueryService review;

    public TtsReviewMvcController(TtsReviewQueryService review) {
        this.review = review;
    }

    @GetMapping("/jobs/{jobId}/preview")
    public ResponseEntity<byte[]> preview(@PathVariable UUID revisionId, @PathVariable UUID jobId) {
        try {
            var content = review.preview(revisionId, jobId);
            if (!"audio/mpeg".equals(content.mediaType())) {
                return ResponseEntity.notFound().build();
            }
            return ResponseEntity.ok()
                    .cacheControl(CacheControl.noStore())
                    .contentType(MediaType.parseMediaType(content.mediaType()))
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline")
                    .header("X-Content-Type-Options", "nosniff")
                    .body(content.bytes());
        } catch (IllegalArgumentException
                 | LearnerMediaService.MediaUnavailableException
                 | LearnerMediaService.MediaIntegrityException unavailable) {
            return ResponseEntity.notFound().build();
        }
    }
}
