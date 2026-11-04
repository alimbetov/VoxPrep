package io.github.alimbetov.voxprep.backend.learner.web;

import io.github.alimbetov.voxprep.backend.learner.application.LearnerExactQuestionService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerExactQuestionService.QuestionPayload;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Exact immutable question contract used by Flutter AssessmentPayloadDecoder. */
@RestController
@RequestMapping("/api/v1/assessment/questions")
public class LearnerExactQuestionController {

    private final LearnerExactQuestionService questions;

    public LearnerExactQuestionController(LearnerExactQuestionService questions) {
        this.questions = questions;
    }

    @GetMapping("/{questionCode}/revisions/{revision}")
    public ResponseEntity<QuestionPayload> get(
            @PathVariable String questionCode,
            @PathVariable int revision,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        // Service checks release membership and ALL parent-test entitlements first.
        QuestionPayload payload = questions.get(questionCode, revision);
        String etag = LearnerHttpCache.weakEtag(
                "exact-question", payload.questionCode(), payload.revision(), payload.checksum());
        return LearnerHttpCache.revalidate(payload, etag, ifNoneMatch);
    }
}
