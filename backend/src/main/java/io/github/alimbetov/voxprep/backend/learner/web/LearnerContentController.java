package io.github.alimbetov.voxprep.backend.learner.web;

import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentSnapshot;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerLocalizationService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerLocalizationSnapshot;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
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
    public ResponseEntity<LearnerContentSnapshot> get(
            @PathVariable String contentType,
            @PathVariable String contentCode,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        LearnerContentSnapshot snapshot = contentService.get(contentType, contentCode);
        String etag = LearnerHttpCache.weakEtag(
                "content",
                snapshot.contentVersion(),
                snapshot.rootSha256(),
                snapshot.contentType(),
                snapshot.contentCode(),
                snapshot.revisionNumber(),
                snapshot.checksumSha256());
        return LearnerHttpCache.revalidate(snapshot, etag, ifNoneMatch);
    }

    @GetMapping("/{contentType}/{contentCode}/localization")
    public ResponseEntity<LearnerLocalizationSnapshot> localization(
            @PathVariable String contentType,
            @PathVariable String contentCode,
            @RequestParam String locale,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        LearnerLocalizationSnapshot snapshot = localizationService.get(contentType, contentCode, locale);
        String etag = LearnerHttpCache.weakEtag(
                "localization",
                snapshot.contentVersion(),
                snapshot.rootSha256(),
                snapshot.contentType(),
                snapshot.contentCode(),
                snapshot.revisionNumber(),
                snapshot.requestedLocale(),
                snapshot.resolvedLocale(),
                snapshot.fallback(),
                snapshot.localizationRevisionNumber(),
                snapshot.localizationChecksumSha256());
        return LearnerHttpCache.revalidate(snapshot, etag, ifNoneMatch);
    }
}
