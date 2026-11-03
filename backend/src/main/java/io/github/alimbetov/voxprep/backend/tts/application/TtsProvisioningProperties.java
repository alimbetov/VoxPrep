package io.github.alimbetov.voxprep.backend.tts.application;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.ArrayList;
import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties(prefix = "voxprep.tts.provisioning")
public class TtsProvisioningProperties {

    @NotNull
    private TtsProvisioningMode mode = TtsProvisioningMode.DISABLED;

    @Valid
    private List<Seed> seeds = new ArrayList<>();

    public TtsProvisioningMode getMode() {
        return mode;
    }

    public void setMode(TtsProvisioningMode mode) {
        this.mode = mode;
    }

    public List<Seed> getSeeds() {
        return seeds;
    }

    public void setSeeds(List<Seed> seeds) {
        this.seeds = seeds == null ? new ArrayList<>() : new ArrayList<>(seeds);
    }

    public static class Seed {
        @NotBlank
        private String locale;
        @NotBlank
        private String voice;
        @NotBlank
        private String quality;

        public String getLocale() {
            return locale;
        }

        public void setLocale(String locale) {
            this.locale = locale;
        }

        public String getVoice() {
            return voice;
        }

        public void setVoice(String voice) {
            this.voice = voice;
        }

        public String getQuality() {
            return quality;
        }

        public void setQuality(String quality) {
            this.quality = quality;
        }

        public TtsModelSelector selector() {
            return new TtsModelSelector(locale, voice, quality);
        }
    }
}
