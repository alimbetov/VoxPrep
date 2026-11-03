package io.github.alimbetov.voxprep.backend.learner.web;

import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentSnapshot;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/content")
public class LearnerContentController {

    private final LearnerContentService contentService;

    public LearnerContentController(LearnerContentService contentService) {
        this.contentService = contentService;
    }

    @GetMapping("/{contentType}/{contentCode}")
    public LearnerContentSnapshot get(
            @PathVariable String contentType,
            @PathVariable String contentCode) {
        return contentService.get(contentType, contentCode);
    }
}
