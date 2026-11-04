package io.github.alimbetov.voxprep.backend.tts.web;

import io.github.alimbetov.voxprep.backend.asset.application.LearnerMediaService;
import io.github.alimbetov.voxprep.backend.content.web.AdminContentStudioMvc;
import io.github.alimbetov.voxprep.backend.tts.application.TtsReviewQueryService;
import io.github.alimbetov.voxprep.backend.tts.application.TtsReviewCommandService;
import java.util.UUID;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;
import org.springframework.web.bind.annotation.RequestMapping;

/** Browser-facing admin MP3 preview, never a RustFS URL. */
@AdminContentStudioMvc
@Controller
@RequestMapping("/admin/content/revisions/{revisionId}/tts")
public class TtsReviewMvcController {
    private final TtsReviewQueryService review;
    private final TtsReviewCommandService command;

    public TtsReviewMvcController(TtsReviewQueryService review, TtsReviewCommandService command) {
        this.review = review;
        this.command = command;
    }

    @PostMapping("/prepare")
    public String prepare(@PathVariable UUID revisionId,
            @RequestParam String audioRole,
            @RequestParam String voiceModelCode,
            RedirectAttributes messages) {
        try {
            var result = command.prepare(revisionId, audioRole, voiceModelCode);
            messages.addFlashAttribute("flashSuccess", result.reused()
                    ? "Matching TTS job already exists; no duplicate was created."
                    : "TTS job prepared; Worker will process it.");
        } catch (IllegalArgumentException | IllegalStateException rejected) {
            messages.addFlashAttribute("flashError",
                    "TTS preparation rejected. Check revision state, audio role and active voice model.");
        }
        return "redirect:/admin/content/revisions/" + revisionId + "/edit";
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
