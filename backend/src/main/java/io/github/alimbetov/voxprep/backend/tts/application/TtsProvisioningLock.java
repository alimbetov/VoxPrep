package io.github.alimbetov.voxprep.backend.tts.application;

import java.util.function.Supplier;

/** Serializes provisioning work for one immutable model identity. */
public interface TtsProvisioningLock {

    <T> T withLock(String modelCode, Supplier<T> action);
}
