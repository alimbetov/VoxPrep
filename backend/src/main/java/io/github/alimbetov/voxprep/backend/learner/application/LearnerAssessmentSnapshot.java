package io.github.alimbetov.voxprep.backend.learner.application;

import java.util.List;
import java.util.Objects;

public record LearnerAssessmentSnapshot(
        long contentVersion,
        String rootSha256,
        String contentCode,
        int revisionNumber,
        String checksumSha256,
        String title,
        String subtitle,
        String description,
        String instructions,
        int passingScorePercent,
        List<Question> questions) {

    public LearnerAssessmentSnapshot {
        if (contentVersion <= 0) {
            throw new IllegalArgumentException("contentVersion must be positive");
        }
        Objects.requireNonNull(rootSha256, "rootSha256");
        Objects.requireNonNull(contentCode, "contentCode");
        Objects.requireNonNull(checksumSha256, "checksumSha256");
        Objects.requireNonNull(title, "title");
        Objects.requireNonNull(subtitle, "subtitle");
        Objects.requireNonNull(description, "description");
        Objects.requireNonNull(instructions, "instructions");
        questions = List.copyOf(Objects.requireNonNull(questions, "questions"));
        if (questions.isEmpty()) {
            throw new IllegalArgumentException("assessment must contain questions");
        }
    }

    public record Question(
            String contentCode,
            int revisionNumber,
            String checksumSha256,
            String questionText,
            List<Option> options) {

        public Question {
            Objects.requireNonNull(contentCode, "contentCode");
            Objects.requireNonNull(checksumSha256, "checksumSha256");
            Objects.requireNonNull(questionText, "questionText");
            options = List.copyOf(Objects.requireNonNull(options, "options"));
        }
    }

    public record Option(String key, String text) {
        public Option {
            Objects.requireNonNull(key, "key");
            Objects.requireNonNull(text, "text");
        }
    }
}
