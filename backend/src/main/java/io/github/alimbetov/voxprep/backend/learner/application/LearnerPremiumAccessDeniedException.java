package io.github.alimbetov.voxprep.backend.learner.application;

/** The exact published revision is in a FULL collection without verified access. */
public class LearnerPremiumAccessDeniedException extends RuntimeException {

    public LearnerPremiumAccessDeniedException() {
        super("Lifetime unlock is required");
    }
}
