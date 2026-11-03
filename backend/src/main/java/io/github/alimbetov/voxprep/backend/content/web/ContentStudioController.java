package io.github.alimbetov.voxprep.backend.content.web;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/admin")
public class ContentStudioController {

    @GetMapping({"", "/"})
    public String dashboard(Model model) {
        model.addAttribute("activeSection", "dashboard");
        return "admin/dashboard";
    }

    @GetMapping("/catalogue")
    public String catalogue(Model model) {
        return section(model, "catalogue", "Catalogue", "Catalogue authoring will be wired in MVC-R2.");
    }

    @GetMapping("/content")
    public String content(Model model) {
        return section(model, "content", "Content", "Content revision editing will be wired in MVC-R3.");
    }

    @GetMapping("/localization")
    public String localization(Model model) {
        return section(model, "localization", "Localization", "Localization authoring will be wired in MVC-R4.");
    }

    @GetMapping("/publication")
    public String publication(Model model) {
        return section(model, "publication", "Publication", "Publication readiness will reuse the existing B6/R5 services.");
    }

    @GetMapping("/imports")
    public String imports(Model model) {
        return section(model, "imports", "Imports", "Import tooling will be added without bypassing application services.");
    }

    private static String section(Model model, String activeSection, String title, String description) {
        model.addAttribute("activeSection", activeSection);
        model.addAttribute("sectionTitle", title);
        model.addAttribute("sectionDescription", description);
        return "admin/section";
    }
}
