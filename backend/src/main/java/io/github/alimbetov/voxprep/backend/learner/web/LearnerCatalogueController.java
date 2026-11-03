package io.github.alimbetov.voxprep.backend.learner.web;

import io.github.alimbetov.voxprep.backend.learner.application.LearnerCatalogueService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerCatalogueSnapshot;
import java.util.Objects;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/catalogue")
public class LearnerCatalogueController {

    private final LearnerCatalogueService catalogueService;

    public LearnerCatalogueController(LearnerCatalogueService catalogueService) {
        this.catalogueService = Objects.requireNonNull(catalogueService, "catalogueService");
    }

    @GetMapping
    public LearnerCatalogueSnapshot getCurrentCatalogue() {
        return catalogueService.getCurrentCatalogue();
    }
}
