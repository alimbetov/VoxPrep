package io.github.alimbetov.voxprep.backend.tts.application;

/** One concrete upstream capable of retrieving pinned TTS model artifacts. */
public interface TtsModelArtifactProvider {

    String providerId();

    byte[] fetch(TtsModelArtifactSource.ArtifactRequest request);
}
