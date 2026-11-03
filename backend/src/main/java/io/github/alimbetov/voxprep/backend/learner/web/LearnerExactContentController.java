package io.github.alimbetov.voxprep.backend.learner.web;

import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentAccessPolicy;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerExactContentPayloadService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerExactContentPayloadService.ExactPayload;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/content")
public class LearnerExactContentController {

    private final LearnerContentAccessPolicy accessPolicy;
    private final LearnerExactContentPayloadService service;

    public LearnerExactContentController(
            LearnerContentAccessPolicy accessPolicy,
            LearnerExactContentPayloadService service) {
        this.accessPolicy = accessPolicy;
        this.service = service;
    }

    @GetMapping("/{contentType}/{contentCode}/revisions/{revision}")
    public ResponseEntity<ExactPayload> get(
            @PathVariable String contentType,
            @PathVariable String contentCode,
            @PathVariable int revision,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        accessPolicy.requireAccessible(contentType, contentCode);
        ExactPayload body = service.get(contentType, contentCode, revision);
        String etag = LearnerHttpCache.weakEtag(
                "exact-content", body.contentType(), body.contentCode(),
                body.revision(), body.checksum());
        return LearnerHttpCache.revalidate(body, etag, ifNoneMatch);
    }
}
