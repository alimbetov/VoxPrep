package io.github.alimbetov.voxprep.backend.content.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

@Embeddable
public class ShadowingSegmentEmbeddable {

    @Column(name = "segment_text", nullable = false, columnDefinition = "text")
    private String text;

    @Column(name = "start_ms")
    private Integer startMs;

    @Column(name = "end_ms")
    private Integer endMs;

    protected ShadowingSegmentEmbeddable() {
    }

    public ShadowingSegmentEmbeddable(String text, Integer startMs, Integer endMs) {
        this.text = ContentEntityRules.requiredBodyText(text, "text");
        if (startMs != null && startMs < 0) {
            throw new IllegalArgumentException("startMs must be >= 0");
        }
        if (endMs != null && endMs < 1) {
            throw new IllegalArgumentException("endMs must be >= 1");
        }
        if (startMs != null && endMs != null && endMs <= startMs) {
            throw new IllegalArgumentException("endMs must be greater than startMs");
        }
        this.startMs = startMs;
        this.endMs = endMs;
    }

    public String getText() {
        return text;
    }

    public Integer getStartMs() {
        return startMs;
    }

    public Integer getEndMs() {
        return endMs;
    }
}
