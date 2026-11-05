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

}
