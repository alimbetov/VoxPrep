package io.github.alimbetov.voxprep.backend.content.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

@Embeddable
public class QuestionOptionEmbeddable {

    private static final int KEY_MAX_LENGTH = 64;

    @Column(name = "option_key", nullable = false, length = KEY_MAX_LENGTH)
    private String key;

    @Column(name = "option_text", nullable = false, columnDefinition = "text")
    private String text;

    @Column(name = "is_correct", nullable = false)
    private boolean correct;

    protected QuestionOptionEmbeddable() {
    }

    public QuestionOptionEmbeddable(String key, String text, boolean correct) {
        this.key = ContentEntityRules.requiredText(key, "optionKey", KEY_MAX_LENGTH);
        if (!this.key.matches("^[A-Za-z0-9._-]+$")) {
            throw new IllegalArgumentException("optionKey contains unsupported characters");
        }
        this.text = ContentEntityRules.requiredBodyText(text, "optionText");
        this.correct = correct;
    }

    public String getKey() {
        return key;
    }

    public String getText() {
        return text;
    }

    public boolean isCorrect() {
        return correct;
    }
}
