package io.github.alimbetov.voxprep.backend.learner.application;

/** Absent or inconsistent immutable Flutter wire snapshot; never substitute mutable authoring data. */
public class LearnerWireSnapshotUnavailableException extends RuntimeException {
    public LearnerWireSnapshotUnavailableException(String message) {
        super(message);
    }
}
