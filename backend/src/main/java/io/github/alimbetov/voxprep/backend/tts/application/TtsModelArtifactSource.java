package io.github.alimbetov.voxprep.backend.tts.application;

/**
 * Provider-neutral artifact retrieval boundary used by TTS provisioning.
 *
 * <p>The provider id comes from immutable model provenance. Implementations must fail closed when
 * the provider is unsupported rather than silently falling back to a generic HTTP client.
 */
public interface TtsModelArtifactSource {

    byte[] fetch(String provider, String url);
}
