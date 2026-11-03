package io.github.alimbetov.voxprep.backend.learner.application;

public class LearnerContentNotFoundException extends RuntimeException {

    public LearnerContentNotFoundException(String contentType, String contentCode) {
        super("published learner content not found: " + contentType + "/" + contentCode);
    }
}
