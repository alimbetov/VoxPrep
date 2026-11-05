package io.github.alimbetov.voxprep.backend.content.web;

import io.github.alimbetov.voxprep.backend.content.application.ContentXmlDryRunService;
import io.github.alimbetov.voxprep.backend.content.application.ContentXmlDryRunService.ValidationReport;
import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.time.Duration;
import java.util.HexFormat;
import jakarta.servlet.http.HttpSession;
import org.springframework.core.io.ClassPathResource;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;

@AdminContentStudioMvc
@Controller
@RequestMapping("/admin/imports")
public final class ContentXmlImportMvcController {
    private final ContentXmlDryRunService validation;
    private final ContentXmlImportService importer;
    private static final String VALIDATED_XML = "voxprepValidatedXml";

    public ContentXmlImportMvcController(ContentXmlDryRunService validation,
            ContentXmlImportService importer) {
        this.validation = validation;
        this.importer = importer;
    }

    @GetMapping
    public String index(Model model) {
        model.addAttribute("activeSection", "imports");
        return "admin/imports/index";
    }

    @GetMapping("/template.xml")
    public ResponseEntity<byte[]> template() throws IOException {
        return download("imports/voxprep-content-template-v1.xml",
                "voxprep-content-template-v1.xml");
    }

    @GetMapping("/schema.xsd")
    public ResponseEntity<byte[]> schema() throws IOException {
        return download("imports/voxprep-content-v1.xsd", "voxprep-content-v1.xsd");
    }

    @PostMapping(path = "/validate", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public String validate(@RequestParam("file") MultipartFile file, Model model, HttpSession session) {
        model.addAttribute("activeSection", "imports");
        session.removeAttribute(VALIDATED_XML);
        ValidationReport result;
        if (file == null || file.isEmpty() || file.getSize() > ContentXmlDryRunService.MAX_BYTES) {
            result = new ValidationReport(false,
                    java.util.List.of("Select an XML file smaller than or equal to 1 MiB."),
                    java.util.List.of());
        } else {
            try {
                var bytes = file.getBytes();
                result = validation.validate(bytes);
                if (result.valid()) {
                    try {
                        var plan = importer.preflight(bytes);
                        model.addAttribute("preflight", plan);
                        session.setAttribute(VALIDATED_XML,
                                new ValidatedXml(sha256(bytes), Instant.now()));
                    } catch (IllegalArgumentException | IllegalStateException conflict) {
                        model.addAttribute("preflightError", "Database preflight rejected: " + safeReason(conflict));
                    }
                }
            } catch (IOException exception) {
                result = new ValidationReport(false,
                        java.util.List.of("Uploaded XML could not be read."),
                        java.util.List.of());
            }
        }
        model.addAttribute("validation", result);
        return "admin/imports/index";
    }

    @PostMapping(path = "/import-drafts", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public String importDrafts(@RequestParam("file") MultipartFile file,
            Model model, HttpSession session) {
        model.addAttribute("activeSection", "imports");
        var evidence = session.getAttribute(VALIDATED_XML);
        if (!(evidence instanceof ValidatedXml validated)
                || Duration.between(validated.createdAt(), Instant.now()).compareTo(Duration.ofMinutes(10)) > 0) {
            model.addAttribute("importError", "Validation expired. Validate the XML again.");
            return "admin/imports/index";
        }
        try {
            if (file.isEmpty() || file.getSize() > ContentXmlDryRunService.MAX_BYTES) {
                throw new IllegalArgumentException("Select the previously validated XML file (maximum 1 MiB).");
            }
            byte[] bytes = file.getBytes();
            if (!MessageDigest.isEqual(validated.checksum().getBytes(java.nio.charset.StandardCharsets.US_ASCII),
                    sha256(bytes).getBytes(java.nio.charset.StandardCharsets.US_ASCII))) {
                throw new IllegalArgumentException("XML changed since validation. Run Validate XML again.");
            }
            var report = importer.importDrafts(bytes);
            model.addAttribute("importReport", report);
            session.removeAttribute(VALIDATED_XML);
        } catch (IllegalArgumentException | IllegalStateException exception) {
            model.addAttribute("importError", "Import rejected: " + safeReason(exception));
        } catch (IOException exception) {
            model.addAttribute("importError", "XML file could not be read.");
        }
        return "admin/imports/index";
    }

    private static String safeReason(Exception exception) {
        var message = exception.getMessage();
        return message != null && message.length() <= 180 ? message : "Invalid or conflicting content";
    }

    private static String sha256(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 unavailable", exception);
        }
    }

    private record ValidatedXml(String checksum, Instant createdAt) {}

    private static ResponseEntity<byte[]> download(String resource, String filename) throws IOException {
        var bytes = new ClassPathResource(resource).getContentAsByteArray();
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .contentType(MediaType.parseMediaType("application/xml"))
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .header("X-Content-Type-Options", "nosniff")
                .body(bytes);
    }
}
