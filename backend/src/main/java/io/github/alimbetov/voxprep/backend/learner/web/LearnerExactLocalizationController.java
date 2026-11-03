package io.github.alimbetov.voxprep.backend.learner.web;

import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentAccessPolicy;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerExactLocalizationService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerExactLocalizationService.ExactLocalization;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/content")
public class LearnerExactLocalizationController {

    private final LearnerContentAccessPolicy access;
    private final LearnerExactLocalizationService service;

    public LearnerExactLocalizationController(
            LearnerContentAccessPolicy access,
            LearnerExactLocalizationService service) {
        this.access = access;
        this.service = service;
    }

    @GetMapping("/{contentType}/{contentCode}/revisions/{contentRevision}/localizations/{locale}/revisions/{localizationRevision}")
    public ResponseEntity<ExactLocalization> get(
            @PathVariable String contentType,
            @PathVariable String contentCode,
            @PathVariable int contentRevision,
            @PathVariable String locale,
            @PathVariable int localizationRevision,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        access.requireAccessible(contentType, contentCode);
        var value = service.get(contentType, contentCode, contentRevision, locale, localizationRevision);
        String etag = LearnerHttpCache.weakEtag("exact-localization",
                value.contentType(), value.contentCode(), value.contentRevision(),
                value.locale(), value.localizationRevision(), value.checksum());
        return LearnerHttpCache.revalidate(value, etag, ifNoneMatch);
    }
}
