package io.github.alimbetov.voxprep.backend.infrastructure.tts;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.alimbetov.voxprep.backend.tts.application.TtsProvisioningLock;
import java.time.Duration;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@ActiveProfiles("test")
@SpringBootTest
class PostgresTtsProvisioningLockIntegrationTest {

    @Autowired
    private TtsProvisioningLock lock;

    @Test
    void serializesSameModelAcrossConcurrentCallers() throws Exception {
        assertThat(lock).isInstanceOf(PostgresTtsProvisioningLock.class);

        var executor = Executors.newFixedThreadPool(2);
        try {
            CountDownLatch start = new CountDownLatch(1);
            AtomicInteger inside = new AtomicInteger();
            AtomicInteger maxInside = new AtomicInteger();

            Future<Void> first = executor.submit(() -> runLocked(start, inside, maxInside));
            Future<Void> second = executor.submit(() -> runLocked(start, inside, maxInside));
            start.countDown();

            first.get(10, TimeUnit.SECONDS);
            second.get(10, TimeUnit.SECONDS);

            assertThat(maxInside.get()).isEqualTo(1);
        } finally {
            executor.shutdownNow();
            assertThat(executor.awaitTermination(Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS)).isTrue();
        }
    }

    private Void runLocked(CountDownLatch start, AtomicInteger inside, AtomicInteger maxInside) throws Exception {
        assertThat(start.await(5, TimeUnit.SECONDS)).isTrue();
        return lock.withLock("en_US.lessac.high", () -> {
            int current = inside.incrementAndGet();
            maxInside.accumulateAndGet(current, Math::max);
            try {
                Thread.sleep(150);
                return null;
            } catch (InterruptedException exception) {
                Thread.currentThread().interrupt();
                throw new IllegalStateException(exception);
            } finally {
                inside.decrementAndGet();
            }
        });
    }
}
