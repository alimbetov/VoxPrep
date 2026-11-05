package io.github.alimbetov.voxprep.backend.content.web;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

/**
 * Admin-only import UI. Preview never writes. Import always reparses the file;
 * no client-submitted approval state or preview token is trusted.
 */
@AdminContentStudioMvc
@Controller
@RequestMapping("/admin/imports")
public class ContentImportMvcController {
    private final ContentBatchImportService importer;

    public ContentImportMvcController(ContentBatchImportService importer) {
        this.importer = importer;
    }

    @GetMapping
    public String index(Model model) {
        model.addAttribute("activeSection", "imports");
        return "admin/imports/index";
    }

    @PostMapping("/preview")
    public String preview(@RequestParam("file") MultipartFile file, Model model) {
        model.addAttribute("activeSection", "imports");
        try {
            var parsed = importer.preview(file.getOriginalFilename(), file.getBytes());
            model.addAttribute("preview", parsed);
        } catch (IllegalArgumentException | java.io.IOException invalid) {
            model.addAttribute("importError", "Import validation failed: " + invalid.getMessage());
        }
        return "admin/imports/index";
    }

    @PostMapping("/import")
    public String importDrafts(@RequestParam("file") MultipartFile file,
            Model model, RedirectAttributes flash) {
        try {
            var count = importer.importDrafts(file.getOriginalFilename(), file.getBytes());
            flash.addFlashAttribute("flashSuccess", "Created " + count
                    + " content drafts. Review and approve them before publication.");
            return "redirect:/admin/content";
        } catch (IllegalArgumentException | java.io.IOException invalid) {
            model.addAttribute("activeSection", "imports");
            model.addAttribute("importError", "Import rejected: " + invalid.getMessage());
            return "admin/imports/index";
        }
    }
}
