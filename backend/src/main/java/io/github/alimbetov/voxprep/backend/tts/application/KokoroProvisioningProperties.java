package io.github.alimbetov.voxprep.backend.tts.application;

import java.util.ArrayList;
import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Explicit opt-in: no network requests or model writes by default.
 * Hashes and pinned upstream URLs must be supplied by the operator after
 * independent model/license review; none are synthesized at runtime.
 */
@ConfigurationProperties(prefix = "voxprep.tts.kokoro-provisioning")
public class KokoroProvisioningProperties {

    private boolean enabled;
    private List<Bundle> bundles = new ArrayList<>();

    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean enabled) { this.enabled = enabled; }
    public List<Bundle> getBundles() { return bundles; }
    public void setBundles(List<Bundle> bundles) {
        this.bundles = bundles == null ? new ArrayList<>() : bundles;
    }

    public static class Bundle {
        private String modelCode;
        private String sourceRepository;
        private String sourceRevision;
        private String licenseName;
        private String licenseReference;
        private List<Artifact> artifacts = new ArrayList<>();
        public String getModelCode() { return modelCode; }
        public void setModelCode(String modelCode) { this.modelCode = modelCode; }
        public String getSourceRepository() { return sourceRepository; }
        public void setSourceRepository(String sourceRepository) { this.sourceRepository = sourceRepository; }
        public String getSourceRevision() { return sourceRevision; }
        public void setSourceRevision(String sourceRevision) { this.sourceRevision = sourceRevision; }
        public String getLicenseName() { return licenseName; }
        public void setLicenseName(String licenseName) { this.licenseName = licenseName; }
        public String getLicenseReference() { return licenseReference; }
        public void setLicenseReference(String licenseReference) { this.licenseReference = licenseReference; }
        public List<Artifact> getArtifacts() { return artifacts; }
        public void setArtifacts(List<Artifact> artifacts) {
            this.artifacts = artifacts == null ? new ArrayList<>() : artifacts;
        }
    }

    public static class Artifact {
        private String path;
        private String role;
        private String url;
        private String sha256;
        private long sizeBytes;
        private String mediaType = "application/octet-stream";
        public String getPath() { return path; }
        public void setPath(String path) { this.path = path; }
        public String getRole() { return role; }
        public void setRole(String role) { this.role = role; }
        public String getUrl() { return url; }
        public void setUrl(String url) { this.url = url; }
        public String getSha256() { return sha256; }
        public void setSha256(String sha256) { this.sha256 = sha256; }
        public long getSizeBytes() { return sizeBytes; }
        public void setSizeBytes(long sizeBytes) { this.sizeBytes = sizeBytes; }
        public String getMediaType() { return mediaType; }
        public void setMediaType(String mediaType) { this.mediaType = mediaType; }
    }
}
