package io.github.alimbetov.voxprep.backend.content.web;

import io.github.alimbetov.voxprep.backend.content.application.ContentAdminQueryService;
import io.github.alimbetov.voxprep.backend.content.application.ContentAuthoringConflictException;
import io.github.alimbetov.voxprep.backend.content.localization.ContentLocalizationAuthoringService;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.UUID;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@AdminContentStudioMvc
@Controller
@RequestMapping("/admin/content")
public class ContentLocalizationMvcController {

    private final ContentAdminQueryService contentQuery;
    private final ContentLocalizationAuthoringService localizations;

    public ContentLocalizationMvcController(
            ContentAdminQueryService contentQuery,
            ContentLocalizationAuthoringService localizations) {
        this.contentQuery = contentQuery;
        this.localizations = localizations;
    }

    @GetMapping("/revisions/{contentId}/localizations")
    public String list(@PathVariable UUID contentId, Model model) {
        model.addAttribute("activeSection", "content");
        model.addAttribute("contentRevision", contentQuery.get(contentId));
        model.addAttribute("localizations", localizations.listByContent(contentId));
        return "admin/content/localizations";
    }

    @GetMapping("/revisions/{contentId}/localizations/new")
    public String createForm(@PathVariable UUID contentId, Model model) {
        var form = new LocalizationForm();
        form.setExpectedVersion(0L);
        return form(model, contentId, null, form);
    }

    @PostMapping("/revisions/{contentId}/localizations")
    public String create(
            @PathVariable UUID contentId,
            @Valid @ModelAttribute("form") LocalizationForm form,
            BindingResult binding,
            Model model,
            RedirectAttributes redirect) {
        if (binding.hasErrors() || !hasTranslation(form, binding)) {
            return form(model, contentId, null, form);
        }
        try {
            var created = localizations.create(contentId, form.getLocale(), checksum(form), fields(form));
            redirect.addFlashAttribute("flashSuccess", "Localization draft created.");
            return editRedirect(created.id());
        } catch (IllegalArgumentException exception) {
            binding.reject("localization.invalid", "Invalid localization fields or locale");
            return form(model, contentId, null, form);
        } catch (IllegalStateException exception) {
            throw new ContentAuthoringConflictException("Localization revision conflict", exception);
        }
    }

    @GetMapping("/localizations/{id}/edit")
    public String edit(@PathVariable UUID id, Model model) {
        var snapshot = localizations.get(id);
        return form(model, snapshot.contentRevisionId(), snapshot, fromSnapshot(snapshot));
    }

    @PostMapping("/localizations/{id}")
    public String update(
            @PathVariable UUID id,
            @Valid @ModelAttribute("form") LocalizationForm form,
            BindingResult binding,
            Model model,
            RedirectAttributes redirect) {
        var snapshot = localizations.get(id);
        if (binding.hasErrors() || !hasTranslation(form, binding)) {
            return form(model, snapshot.contentRevisionId(), snapshot, form);
        }
        try {
            localizations.updateDraft(id, form.getExpectedVersion(), checksum(form), fields(form));
            redirect.addFlashAttribute("flashSuccess", "Localization draft saved.");
            return editRedirect(id);
        } catch (IllegalArgumentException exception) {
            binding.reject("localization.invalid", "Invalid localization fields");
            return form(model, snapshot.contentRevisionId(), snapshot, form);
        } catch (IllegalStateException exception) {
            throw new ContentAuthoringConflictException("Localization revision conflict", exception);
        }
    }

    private String form(
            Model model,
            UUID contentId,
            ContentLocalizationAuthoringService.Snapshot snapshot,
            LocalizationForm form) {
        model.addAttribute("activeSection", "content");
        model.addAttribute("contentRevision", contentQuery.get(contentId));
        model.addAttribute("localization", snapshot);
        model.addAttribute("form", form);
        return "admin/content/localization-form";
    }

    private static LocalizationForm fromSnapshot(ContentLocalizationAuthoringService.Snapshot snapshot) {
        var form = new LocalizationForm();
        form.setExpectedVersion(snapshot.version());
        form.setLocale(snapshot.locale());
        form.setTitle(snapshot.title());
        form.setSubtitle(snapshot.subtitle());
        form.setDescription(snapshot.description());
        form.setTranslation(snapshot.translation());
        form.setHint(snapshot.hint());
        form.setExplanation(snapshot.explanation());
        return form;
    }

    private static ContentLocalizationAuthoringService.Fields fields(LocalizationForm form) {
        return new ContentLocalizationAuthoringService.Fields(
                form.getTitle(), form.getSubtitle(), form.getDescription(),
                form.getTranslation(), form.getHint(), form.getExplanation());
    }

    private static boolean hasTranslation(LocalizationForm form, BindingResult binding) {
        if (java.util.stream.Stream.of(form.getTitle(), form.getSubtitle(), form.getDescription(),
                form.getTranslation(), form.getHint(), form.getExplanation())
                .allMatch(value -> value == null || value.isBlank())) {
            binding.reject("localization.empty", "At least one localized field is required");
            return false;
        }
        return true;
    }

    private static Sha256Digest checksum(LocalizationForm form) {
        try {
            var digest = MessageDigest.getInstance("SHA-256");
            var text = String.join("\u001f", safe(form.getTitle()), safe(form.getSubtitle()),
                    safe(form.getDescription()), safe(form.getTranslation()),
                    safe(form.getHint()), safe(form.getExplanation()));
            return new Sha256Digest(HexFormat.of().formatHex(digest.digest(text.getBytes(StandardCharsets.UTF_8))));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 unavailable", exception);
        }
    }

    private static String safe(String value) {
        return value == null ? "" : value.trim();
    }

    private static String editRedirect(UUID id) {
        return "redirect:/admin/content/localizations/" + id + "/edit";
    }

    public static class LocalizationForm {
        @NotNull
        @Min(0)
        private Long expectedVersion;

        @NotBlank
        @Size(max = 64)
        @Pattern(regexp = "[A-Za-z]{2,8}(-[A-Za-z0-9]{1,8})*")
        private String locale;

        @Size(max = 256)
        private String title;

        @Size(max = 512)
        private String subtitle;

        @Size(max = 4096)
        private String description;

        private String translation;
        private String hint;
        private String explanation;

        public Long getExpectedVersion() { return expectedVersion; }
        public void setExpectedVersion(Long value) { this.expectedVersion = value; }
        public String getLocale() { return locale; }
        public void setLocale(String value) { this.locale = value; }
        public String getTitle() { return title; }
        public void setTitle(String value) { this.title = value; }
        public String getSubtitle() { return subtitle; }
        public void setSubtitle(String value) { this.subtitle = value; }
        public String getDescription() { return description; }
        public void setDescription(String value) { this.description = value; }
        public String getTranslation() { return translation; }
        public void setTranslation(String value) { this.translation = value; }
        public String getHint() { return hint; }
        public void setHint(String value) { this.hint = value; }
        public String getExplanation() { return explanation; }
        public void setExplanation(String value) { this.explanation = value; }
    }
}
