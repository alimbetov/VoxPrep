package io.github.alimbetov.voxprep.backend.content.web;

import jakarta.servlet.http.HttpSession;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
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
    public String preview(@RequestParam("file") MultipartFile file,
            HttpSession session, Model model) {
        model.addAttribute("activeSection", "imports");
        try {
            byte[] bytes = file.getBytes();
            var parsed = importer.preview(file.getOriginalFilename(), bytes);
            session.setAttribute("voxprep.import.preview", fingerprint(bytes));
            model.addAttribute("preview", parsed);
        } catch (IllegalArgumentException | java.io.IOException invalid) {
            session.removeAttribute("voxprep.import.preview");
            model.addAttribute("importError", "Import validation failed: " + invalid.getMessage());
        }
        return "admin/imports/index";
    }

    @PostMapping("/import")
    public String importDrafts(@RequestParam("file") MultipartFile file,
            HttpSession session, Model model, RedirectAttributes flash) {
        try {
            byte[] bytes = file.getBytes();
            var previewFingerprint = session.getAttribute("voxprep.import.preview");
            if (!fingerprint(bytes).equals(previewFingerprint)) {
                throw new IllegalArgumentException(
                        "Preview this exact file in the same session before import");
            }
            var count = importer.importDrafts(file.getOriginalFilename(), bytes);
            session.removeAttribute("voxprep.import.preview");
            flash.addFlashAttribute("flashSuccess", "Created " + count
                    + " content drafts. Review and approve them before publication.");
            return "redirect:/admin/content";
        } catch (IllegalArgumentException | java.io.IOException invalid) {
            model.addAttribute("activeSection", "imports");
            model.addAttribute("importError", "Import rejected: " + invalid.getMessage());
            return "admin/imports/index";
        }
    }

    private static String fingerprint(byte[] content) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(content));
        } catch (NoSuchAlgorithmException impossible) {
            throw new IllegalStateException("SHA-256 unavailable", impossible);
        }
    }
}
