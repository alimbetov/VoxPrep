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
    public String localization(Model model) {
        return section(model, "localization", "Localization", "Localization authoring will be wired in MVC-R4.");
    }

    private static String section(Model model, String activeSection, String title, String description) {
        model.addAttribute("activeSection", activeSection);
        model.addAttribute("sectionTitle", title);
        model.addAttribute("sectionDescription", description);
        return "admin/section";
    }
}
