package io.github.alimbetov.voxprep.backend.infrastructure.tts;

import io.github.alimbetov.voxprep.backend.tts.application.TtsProvisioningLock;
import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.locks.ReentrantLock;
import java.util.function.Supplier;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

@Component
@Profile({"default", "dev"})
public class LocalTtsProvisioningLock implements TtsProvisioningLock {

    private final ConcurrentHashMap<String, ReentrantLock> locks = new ConcurrentHashMap<>();

    @Override
    public <T> T withLock(String modelCode, Supplier<T> action) {
        Objects.requireNonNull(modelCode, "modelCode");
        Objects.requireNonNull(action, "action");
        ReentrantLock lock = locks.computeIfAbsent(modelCode, ignored -> new ReentrantLock());
        lock.lock();
        try {
            return action.get();
        } finally {
            lock.unlock();
        }
    }
}
