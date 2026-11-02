package io.github.alimbetov.voxprep.backend.content.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

@Embeddable
public class TopicSectionEmbeddable {

    @Column(name = "heading", nullable = false, columnDefinition = "text")
    private String heading;

    @Column(name = "section_text", nullable = false, columnDefinition = "text")
    private String text;

    protected TopicSectionEmbeddable() {
    }

    public TopicSectionEmbeddable(String heading, String text) {
        this.heading = ContentEntityRules.requiredBodyText(heading, "heading");
        this.text = ContentEntityRules.requiredBodyText(text, "text");
    }

    public String getHeading() {
        return heading;
    }

    public String getText() {
        return text;
    }
}
