package io.github.alimbetov.voxprep.backend.asset.web;

import io.github.alimbetov.voxprep.backend.asset.application.ExternalLearningVideoService;
import io.github.alimbetov.voxprep.backend.content.web.AdminContentStudioMvc;
import io.github.alimbetov.voxprep.backend.content.application.ContentAuthoringConflictException;
import java.util.UUID;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

/** ADMIN security and Spring CSRF apply to all modifications. */
@AdminContentStudioMvc
@Controller
@RequestMapping("/admin/content/revisions/{revisionId}/external-video")
public class ExternalVideoAdminController {
    private final ExternalLearningVideoService service;

    public ExternalVideoAdminController(ExternalLearningVideoService service) {
        this.service = service;
    }

    @PostMapping
    public String save(@PathVariable UUID revisionId, @RequestParam String url,
            @RequestParam String title, RedirectAttributes messages) {
        try {
            service.save(revisionId, url, title);
            messages.addFlashAttribute("flashSuccess", "Ссылка на учебное видео сохранена.");
        } catch (IllegalArgumentException exception) {
            messages.addFlashAttribute("flashError", "Укажите корректный HTTPS YouTube URL и название.");
        } catch (IllegalStateException exception) {
            throw new ContentAuthoringConflictException(exception.getMessage(), exception);
        }
        return redirect(revisionId);
    }

    @PostMapping("/remove")
    public String remove(@PathVariable UUID revisionId, RedirectAttributes messages) {
        try {
            service.remove(revisionId);
        } catch (IllegalStateException exception) {
            throw new ContentAuthoringConflictException(exception.getMessage(), exception);
        }
        messages.addFlashAttribute("flashSuccess", "Видеоссылка удалена.");
        return redirect(revisionId);
    }

    private static String redirect(UUID revisionId) {
        return "redirect:/admin/content/revisions/" + revisionId + "/edit";
    }
}
