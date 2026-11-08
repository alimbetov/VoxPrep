package io.github.alimbetov.voxprep.backend.content.web;

import io.github.alimbetov.voxprep.backend.content.application.ContentAdminQueryService;
import io.github.alimbetov.voxprep.backend.content.application.ContentAuthoringConflictException;
import io.github.alimbetov.voxprep.backend.content.application.ContentAuthoringService;
import io.github.alimbetov.voxprep.backend.content.application.ContentRevisionSnapshot;
import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.tts.application.TtsReviewQueryService;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import jakarta.validation.Valid;
import java.util.UUID;
import java.util.List;
import java.util.function.Supplier;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@AdminContentStudioMvc
@Controller
@RequestMapping("/admin/content")
public class ContentMvcController {

    private static final int PAGE_SIZE = 25;

    private final ContentAdminQueryService query;
    private final ContentAuthoringService authoring;
    private final ContentMvcMapper mapper;
    private final TtsReviewQueryService ttsReview;
    private final io.github.alimbetov.voxprep.backend.asset.application.MediaLibraryService mediaLibrary;
    private final io.github.alimbetov.voxprep.backend.asset.application.ExternalLearningVideoService externalVideos;

    public ContentMvcController(
            ContentAdminQueryService query,
            ContentAuthoringService authoring,
            ContentMvcMapper mapper,
            TtsReviewQueryService ttsReview,
            io.github.alimbetov.voxprep.backend.asset.application.MediaLibraryService mediaLibrary,
            io.github.alimbetov.voxprep.backend.asset.application.ExternalLearningVideoService externalVideos) {
        this.query = query;
        this.authoring = authoring;
        this.mapper = mapper;
        this.ttsReview = ttsReview;
        this.mediaLibrary = mediaLibrary;
        this.externalVideos = externalVideos;
    }

    @GetMapping
    public String index(@RequestParam(defaultValue = "0") int page, Model model) {
        model.addAttribute("activeSection", "content");
        model.addAttribute("revisions", query.list(page, PAGE_SIZE));
        return "admin/content/index";
    }

    /** Authenticated admin lookup; never accepts a client-supplied approval state. */
    @GetMapping("/questions/approved")
    @ResponseBody
    public QuestionChoicesResponse approvedQuestions(
            @RequestParam(defaultValue = "") String q,
            @RequestParam(defaultValue = "0") int page) {
        var results = query.approvedQuestions(q, page);
        return new QuestionChoicesResponse(results.getContent(), results.hasNext());
    }

    public record QuestionChoicesResponse(
            List<ContentAdminQueryService.QuestionChoice> items, boolean hasNext) {}

    @GetMapping("/revisions/new")
    public String newRevision(Model model) {
        var form = new ContentMvcForms.DraftForm();
        form.setExpectedVersion(0L);
        form.setMinutes(2);
        form.setAvailability("ACTIVE");
        form.setBodyType("phrase");
        form.setSkillCodes("SPEAKING");
        return newRevisionForm(model, form);
    }

    @PostMapping("/revisions")
    public String createRevision(
            @RequestParam String contentCode,
            @Valid @ModelAttribute("form") ContentMvcForms.DraftForm form,
            BindingResult binding,
            Model model,
            RedirectAttributes redirect) {
        if (form.getExpectedVersion() == null || form.getExpectedVersion() != 0L) {
            binding.reject("content.initial.version", "New content must start at revision 1");
        }
        if (binding.hasErrors()) {
            return newRevisionForm(model, form);
        }
        try {
            var created = authoring.createInitialRevision(new BusinessCode(contentCode), mapper.toCommand(form));
            redirect.addFlashAttribute("flashSuccess", "New content draft created.");
            return editRedirect(created.getId());
        } catch (IllegalArgumentException exception) {
            binding.reject("content.initial.invalid", safeBodyMessage(exception));
            return newRevisionForm(model, form);
        } catch (IllegalStateException exception) {
            throw conflict(exception);
        }
    }

    private static String newRevisionForm(Model model, ContentMvcForms.DraftForm form) {
        model.addAttribute("activeSection", "content");
        model.addAttribute("form", form);
        return "admin/content/new";
    }

    @GetMapping("/revisions/{revisionId}/edit")
    public String edit(@PathVariable UUID revisionId, Model model) {
        var revision = query.get(revisionId);
        return form(model, revision, mapper.toForm(revision), lifecycleForm(revision));
    }

    @PostMapping("/revisions/{revisionId}")
    public String update(
            @PathVariable UUID revisionId,
            @Valid @ModelAttribute("form") ContentMvcForms.DraftForm form,
            BindingResult binding,
            Model model,
            RedirectAttributes redirect) {
        var revision = query.get(revisionId);
        if (!revision.contentType().wireName().equals(form.getBodyType())) {
            binding.reject("content.type.immutable", "Content type cannot be changed");
        }
        if (binding.hasErrors()) {
            return form(model, revision, form, lifecycleForm(revision));
        }

        try {
            authoring.updateDraft(revisionId, form.getExpectedVersion(), mapper.toCommand(form));
        } catch (IllegalArgumentException exception) {
            binding.reject("content.body.invalid", safeBodyMessage(exception));
            return form(model, revision, form, lifecycleForm(revision));
        } catch (IllegalStateException exception) {
            throw conflict(exception);
        }

        redirect.addFlashAttribute("flashSuccess", "Content draft saved.");
        return editRedirect(revisionId);
    }

    @PostMapping("/revisions/{revisionId}/ready-for-audio")
    public String readyForAudio(
            @PathVariable UUID revisionId,
            @Valid @ModelAttribute("lifecycleForm") ContentLifecycleMvcForm lifecycleForm,
            BindingResult binding,
            Model model,
            RedirectAttributes redirect) {
        var revision = query.get(revisionId);
        if (binding.hasErrors()) {
            return form(model, revision, mapper.toForm(revision), lifecycleForm);
        }
        lifecycle(() -> authoring.markReadyForAudio(revisionId, lifecycleForm.getExpectedVersion()));
        redirect.addFlashAttribute("flashSuccess", "Content is ready for audio.");
        return editRedirect(revisionId);
    }

    @PostMapping("/revisions/{revisionId}/review")
    public String submitForReview(
            @PathVariable UUID revisionId,
            @Valid @ModelAttribute("lifecycleForm") ContentLifecycleMvcForm lifecycleForm,
            BindingResult binding,
            Authentication authentication,
            Model model,
            RedirectAttributes redirect) {
        var revision = query.get(revisionId);
        if (binding.hasErrors()) {
            return form(model, revision, mapper.toForm(revision), lifecycleForm);
        }
        lifecycle(() -> authoring.submitForReview(
                revisionId,
                lifecycleForm.getExpectedVersion(),
                authentication.getName(),
                lifecycleForm.getReason(),
                lifecycleForm.getComment()));
        redirect.addFlashAttribute("flashSuccess", "Content submitted for review.");
        return editRedirect(revisionId);
    }

    @PostMapping("/revisions/{revisionId}/approve")
    public String approve(
            @PathVariable UUID revisionId,
            @Valid @ModelAttribute("lifecycleForm") ContentLifecycleMvcForm lifecycleForm,
            BindingResult binding,
            Authentication authentication,
            Model model,
            RedirectAttributes redirect) {
        var revision = query.get(revisionId);
        if (binding.hasErrors()) {
            return form(model, revision, mapper.toForm(revision), lifecycleForm);
        }
        lifecycle(() -> authoring.approve(
                revisionId,
                lifecycleForm.getExpectedVersion(),
                authentication.getName(),
                lifecycleForm.getReason(),
                lifecycleForm.getComment()));
        redirect.addFlashAttribute("flashSuccess", "Content approved.");
        return editRedirect(revisionId);
    }

    @PostMapping("/revisions/{revisionId}/next")
    public String createNextRevision(
            @PathVariable UUID revisionId,
            @Valid @ModelAttribute("lifecycleForm") ContentLifecycleMvcForm lifecycleForm,
            BindingResult binding,
            Model model,
            RedirectAttributes redirect) {
        var revision = query.get(revisionId);
        if (binding.hasErrors()) {
            return form(model, revision, mapper.toForm(revision), lifecycleForm);
        }
        var created = lifecycle(() -> authoring.createNextRevision(revisionId, lifecycleForm.getExpectedVersion()));
        redirect.addFlashAttribute("flashSuccess", "New draft revision created.");
        return editRedirect(created.getId());
    }

    private String form(
            Model model,
            ContentRevisionSnapshot revision,
            ContentMvcForms.DraftForm form,
            ContentLifecycleMvcForm lifecycleForm) {
        model.addAttribute("activeSection", "content");
        model.addAttribute("revision", revision);
        model.addAttribute("imageAssets", mediaLibrary.boundImages(revision.id()));
        model.addAttribute("externalVideo", externalVideos.find(revision.id()).orElse(null));
        model.addAttribute("form", form);
        model.addAttribute("lifecycleForm", lifecycleForm);
        model.addAttribute("ttsJobs", ttsReview.latest(revision.id()));
        if (revision.lifecycle() == ContentLifecycleStatus.READY_FOR_AUDIO) {
            model.addAttribute("ttsModels", ttsReview.availableModels());
            model.addAttribute("ttsKokoroEnabled", ttsReview.kokoroEnabled());
            model.addAttribute("ttsRoles", ttsReview.rolesFor(revision.contentType()));
        }
        model.addAttribute("availabilityValues", AvailabilityStatus.values());
        return "admin/content/form";
    }

    private static ContentLifecycleMvcForm lifecycleForm(ContentRevisionSnapshot revision) {
        var form = new ContentLifecycleMvcForm();
        form.setExpectedVersion(revision.version());
        return form;
    }

    private static <T> T lifecycle(Supplier<T> action) {
        try {
            return action.get();
        } catch (IllegalStateException exception) {
            throw conflict(exception);
        }
    }

    private static ContentAuthoringConflictException conflict(IllegalStateException exception) {
        return new ContentAuthoringConflictException(exception.getMessage(), exception);
    }

    private static String editRedirect(UUID revisionId) {
        return "redirect:/admin/content/revisions/" + revisionId + "/edit";
    }

    private static String safeBodyMessage(IllegalArgumentException exception) {
        var message = exception.getMessage();
        if (message == null || message.isBlank()) {
            return "Content body is invalid";
        }
        return message.length() > 160 ? "Content body is invalid" : message;
    }
}
