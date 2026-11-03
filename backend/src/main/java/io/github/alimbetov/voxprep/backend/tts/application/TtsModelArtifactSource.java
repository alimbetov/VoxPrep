package io.github.alimbetov.voxprep.backend.tts.application;

import java.util.Objects;

/** Provider-neutral artifact retrieval boundary used by TTS provisioning. */
public interface TtsModelArtifactSource {

    byte[] fetch(ArtifactRequest request);

    record ArtifactRequest(String provider, String repository, String revision, String url) {
        public ArtifactRequest {
            provider = required(provider, "provider");
            repository = required(repository, "repository");
            revision = required(revision, "revision");
            url = required(url, "url");
        }

        private static String required(String value, String field) {
            Objects.requireNonNull(value, field);
            String normalized = value.strip();
            if (normalized.isEmpty() || !normalized.equals(value)) {
                throw new IllegalArgumentException("Invalid " + field);
            }
            return normalized;
        }
    }
}
