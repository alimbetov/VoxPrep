package io.github.alimbetov.voxprep.backend.learner.web;

import io.github.alimbetov.voxprep.backend.learner.application.LearnerAssessmentService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerAssessmentSnapshot;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/assessments")
public class LearnerAssessmentController {

    private final LearnerAssessmentService assessmentService;

    public LearnerAssessmentController(LearnerAssessmentService assessmentService) {
        this.assessmentService = assessmentService;
    }

    @GetMapping("/practice-tests/{contentCode}")
    public LearnerAssessmentSnapshot getPracticeTest(@PathVariable String contentCode) {
        return assessmentService.getPracticeTest(contentCode);
    }
}
