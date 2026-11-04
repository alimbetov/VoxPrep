package io.github.alimbetov.voxprep.backend.learner.web;

import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentAccessPolicy;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerAssessmentService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerAssessmentSnapshot;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/assessments")
public class LearnerAssessmentController {

    private final LearnerContentAccessPolicy accessPolicy;
    private final LearnerAssessmentService assessmentService;

    public LearnerAssessmentController(
            LearnerAssessmentService assessmentService,
            LearnerContentAccessPolicy accessPolicy) {
        this.assessmentService = assessmentService;
        this.accessPolicy = accessPolicy;
    }

    @GetMapping("/practice-tests/{contentCode}")
    public ResponseEntity<LearnerAssessmentSnapshot> getPracticeTest(
            @PathVariable String contentCode,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        accessPolicy.requireAccessible("practice_test", contentCode);
        LearnerAssessmentSnapshot snapshot = assessmentService.getPracticeTest(contentCode);
        String etag = LearnerHttpCache.weakEtag(
                "assessment",
                snapshot.contentVersion(),
                snapshot.rootSha256(),
                snapshot.contentCode(),
                snapshot.revisionNumber(),
                snapshot.checksumSha256());
        return LearnerHttpCache.revalidate(snapshot, etag, ifNoneMatch);
    }
}
