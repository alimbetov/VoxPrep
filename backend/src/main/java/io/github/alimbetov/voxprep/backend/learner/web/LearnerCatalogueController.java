package io.github.alimbetov.voxprep.backend.learner.web;

import io.github.alimbetov.voxprep.backend.learner.application.LearnerCatalogueService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerCatalogueSnapshot;
import java.util.Objects;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
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
    public ResponseEntity<LearnerCatalogueSnapshot> getCurrentCatalogue(
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        LearnerCatalogueSnapshot snapshot = catalogueService.getCurrentCatalogue();
        String etag = LearnerHttpCache.weakEtag(
                "catalogue",
                snapshot.contentVersion(),
                snapshot.rootSha256());
        return LearnerHttpCache.revalidate(snapshot, etag, ifNoneMatch);
    }
}
