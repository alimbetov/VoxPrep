package io.github.alimbetov.voxprep.backend.learner.web;

import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentSnapshot;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerLocalizationService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerLocalizationSnapshot;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/content")
public class LearnerContentController {

    private final LearnerContentService contentService;
    private final LearnerLocalizationService localizationService;

    public LearnerContentController(
            LearnerContentService contentService,
            LearnerLocalizationService localizationService) {
        this.contentService = contentService;
        this.localizationService = localizationService;
    }

    @GetMapping("/{contentType}/{contentCode}")
    public LearnerContentSnapshot get(
            @PathVariable String contentType,
            @PathVariable String contentCode) {
        return contentService.get(contentType, contentCode);
    }

    @GetMapping("/{contentType}/{contentCode}/localization")
    public LearnerLocalizationSnapshot localization(
            @PathVariable String contentType,
            @PathVariable String contentCode,
            @RequestParam String locale) {
        return localizationService.get(contentType, contentCode, locale);
    }
}
