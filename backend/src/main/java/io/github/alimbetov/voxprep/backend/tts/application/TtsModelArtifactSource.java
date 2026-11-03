package io.github.alimbetov.voxprep.backend.tts.application;

public interface TtsModelArtifactSource {

    byte[] fetch(String url);
}
