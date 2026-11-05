package io.github.alimbetov.voxprep.backend.content.web;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@AdminContentStudioMvc
@Controller
@RequestMapping("/admin")
public class ContentStudioController {

    @GetMapping({"", "/"})
    public String dashboard(Model model) {
        model.addAttribute("activeSection", "dashboard");
        return "admin/dashboard";
    }

    @GetMapping("/localization")
    public String localization() {
        // Localizations are edited in the context of a concrete content revision.
        // Route the administrator to real content authoring instead of a
        // misleading MVC-R1 placeholder.
        return "redirect:/admin/content";
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
