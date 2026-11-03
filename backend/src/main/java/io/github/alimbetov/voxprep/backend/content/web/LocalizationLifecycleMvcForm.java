package io.github.alimbetov.voxprep.backend.content.web;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public class LocalizationLifecycleMvcForm {

    @NotNull
    @Min(0)
    private Long expectedVersion;

    @Size(max = 512)
    private String reason;

    @Size(max = 2048)
    private String comment;

    public Long getExpectedVersion() { return expectedVersion; }
    public void setExpectedVersion(Long value) { expectedVersion = value; }
    public String getReason() { return reason; }
    public void setReason(String value) { reason = value; }
    public String getComment() { return comment; }
    public void setComment(String value) { comment = value; }
}
