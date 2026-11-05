package io.github.alimbetov.voxprep.backend.content.web;

import io.github.alimbetov.voxprep.backend.content.application.ContentXmlDryRunService;
import io.github.alimbetov.voxprep.backend.content.application.ContentXmlDryRunService.ValidationReport;
import java.io.IOException;
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

    public ContentXmlImportMvcController(ContentXmlDryRunService validation) {
        this.validation = validation;
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
    public String validate(@RequestParam("file") MultipartFile file, Model model) {
        model.addAttribute("activeSection", "imports");
        ValidationReport result;
        if (file == null || file.isEmpty() || file.getSize() > ContentXmlDryRunService.MAX_BYTES) {
            result = new ValidationReport(false,
                    java.util.List.of("Select an XML file smaller than or equal to 1 MiB."),
                    java.util.List.of());
        } else {
            try {
                result = validation.validate(file.getBytes());
            } catch (IOException exception) {
                result = new ValidationReport(false,
                        java.util.List.of("Uploaded XML could not be read."),
                        java.util.List.of());
            }
        }
        model.addAttribute("validation", result);
        return "admin/imports/index";
    }

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
