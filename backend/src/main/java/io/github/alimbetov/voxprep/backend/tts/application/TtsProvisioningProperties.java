package io.github.alimbetov.voxprep.backend.tts.application;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
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
        @NotBlank private String locale;
        @NotBlank private String voice;
        @NotBlank private String quality;
        @NotBlank private String sourceProvider;
        @NotBlank private String sourceRepository;
        @NotBlank private String sourceRevision;
        @NotBlank private String engineVersion;
        @NotBlank private String modelVersion;
        @NotBlank private String modelUrl;
        @NotBlank private String configUrl;
        @Pattern(regexp = "[0-9a-f]{64}") private String modelSha256;
        @Pattern(regexp = "[0-9a-f]{64}") private String configSha256;
        @NotBlank private String licenseName;
        @NotBlank private String licenseReference;

        public String getLocale() { return locale; }
        public void setLocale(String locale) { this.locale = locale; }
        public String getVoice() { return voice; }
        public void setVoice(String voice) { this.voice = voice; }
        public String getQuality() { return quality; }
        public void setQuality(String quality) { this.quality = quality; }
        public String getSourceProvider() { return sourceProvider; }
        public void setSourceProvider(String sourceProvider) { this.sourceProvider = sourceProvider; }
        public String getSourceRepository() { return sourceRepository; }
        public void setSourceRepository(String sourceRepository) { this.sourceRepository = sourceRepository; }
        public String getSourceRevision() { return sourceRevision; }
        public void setSourceRevision(String sourceRevision) { this.sourceRevision = sourceRevision; }
        public String getEngineVersion() { return engineVersion; }
        public void setEngineVersion(String engineVersion) { this.engineVersion = engineVersion; }
        public String getModelVersion() { return modelVersion; }
        public void setModelVersion(String modelVersion) { this.modelVersion = modelVersion; }
        public String getModelUrl() { return modelUrl; }
        public void setModelUrl(String modelUrl) { this.modelUrl = modelUrl; }
        public String getConfigUrl() { return configUrl; }
        public void setConfigUrl(String configUrl) { this.configUrl = configUrl; }
        public String getModelSha256() { return modelSha256; }
        public void setModelSha256(String modelSha256) { this.modelSha256 = modelSha256; }
        public String getConfigSha256() { return configSha256; }
        public void setConfigSha256(String configSha256) { this.configSha256 = configSha256; }
        public String getLicenseName() { return licenseName; }
        public void setLicenseName(String licenseName) { this.licenseName = licenseName; }
        public String getLicenseReference() { return licenseReference; }
        public void setLicenseReference(String licenseReference) { this.licenseReference = licenseReference; }

        public TtsModelSelector selector() {
            return new TtsModelSelector(locale, voice, quality);
        }

        public TtsModelCatalogGateway.ModelDescriptor descriptor() {
            return new TtsModelCatalogGateway.ModelDescriptor(
                    sourceProvider,
                    sourceRepository,
                    sourceRevision,
                    engineVersion,
                    modelVersion,
                    modelUrl,
                    configUrl,
                    modelSha256,
                    configSha256,
                    licenseName,
                    licenseReference);
        }
    }
}
