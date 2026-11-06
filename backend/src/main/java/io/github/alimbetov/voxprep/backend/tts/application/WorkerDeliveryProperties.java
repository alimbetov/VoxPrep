package io.github.alimbetov.voxprep.backend.tts.application;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties(prefix = "voxprep.worker-delivery")
public class WorkerDeliveryProperties {

    @NotBlank
    private String apiKey;

    /** Optional separate identity; absent by default, so Kokoro remains unavailable. */
    private String kokoroApiKey = "";

    private boolean kokoroEnabled = false;

    @NotNull
    private Duration urlTtl = Duration.ofMinutes(5);

    @NotNull
    private Duration leaseDuration = Duration.ofMinutes(2);

    public String getApiKey() {
        return apiKey;
    }

    public void setApiKey(String apiKey) {
        this.apiKey = apiKey;
    }

    public String getKokoroApiKey() {
        return kokoroApiKey;
    }

    public void setKokoroApiKey(String kokoroApiKey) {
        this.kokoroApiKey = kokoroApiKey == null ? "" : kokoroApiKey;
    }

    public boolean isKokoroEnabled() {
        return kokoroEnabled;
    }

    public void setKokoroEnabled(boolean kokoroEnabled) {
        this.kokoroEnabled = kokoroEnabled;
    }

    public Duration getUrlTtl() {
        return urlTtl;
    }

    public void setUrlTtl(Duration urlTtl) {
        this.urlTtl = urlTtl;
    }

    public Duration getLeaseDuration() {
        return leaseDuration;
    }

    public void setLeaseDuration(Duration leaseDuration) {
        this.leaseDuration = leaseDuration;
    }
}
