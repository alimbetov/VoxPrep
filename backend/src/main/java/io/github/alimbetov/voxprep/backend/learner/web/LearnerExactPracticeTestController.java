package io.github.alimbetov.voxprep.backend.learner.web;

import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentAccessPolicy;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerExactPracticeTestService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerExactPracticeTestService.ExactPracticeTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Exact immutable practice-test DTO consumed by Flutter AssessmentPayloadDecoder. */
@RestController
@RequestMapping("/api/v1/assessment/practice-tests")
public class LearnerExactPracticeTestController {

    private final LearnerContentAccessPolicy access;
    private final LearnerExactPracticeTestService service;

    public LearnerExactPracticeTestController(
            LearnerContentAccessPolicy access,
            LearnerExactPracticeTestService service) {
        this.access = access;
        this.service = service;
    }

    @GetMapping("/{practiceTestCode}/revisions/{revision}")
    public ResponseEntity<ExactPracticeTest> get(
            @PathVariable String practiceTestCode,
            @PathVariable int revision,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        // Evaluate frozen FREE/FULL before requesting a payload or returning 304.
        access.requireAccessible("practice_test", practiceTestCode);
        var value = service.get(practiceTestCode, revision);
        var etag = LearnerHttpCache.weakEtag(
                "exact-practice-test", value.practiceTestCode(), value.revision(), value.checksum());
        return LearnerHttpCache.revalidate(value, etag, ifNoneMatch);
    }
}
