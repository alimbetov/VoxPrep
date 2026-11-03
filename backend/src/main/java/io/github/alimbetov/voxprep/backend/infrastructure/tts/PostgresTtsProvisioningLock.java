package io.github.alimbetov.voxprep.backend.infrastructure.tts;

import io.github.alimbetov.voxprep.backend.tts.application.TtsProvisioningLock;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Objects;
import java.util.function.Supplier;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
@Profile({"test", "prod"})
public class PostgresTtsProvisioningLock implements TtsProvisioningLock {

    private final JdbcTemplate jdbcTemplate;

    public PostgresTtsProvisioningLock(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = Objects.requireNonNull(jdbcTemplate, "jdbcTemplate");
    }

    @Override
    public <T> T withLock(String modelCode, Supplier<T> action) {
        Objects.requireNonNull(modelCode, "modelCode");
        Objects.requireNonNull(action, "action");
        long key = lockKey(modelCode);
        return jdbcTemplate.execute((ConnectionCallback<T>) connection -> {
            advisoryLock(connection, key, true);
            try {
                return action.get();
            } finally {
                advisoryLock(connection, key, false);
            }
        });
    }

    static long lockKey(String modelCode) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(modelCode.getBytes(StandardCharsets.UTF_8));
            return ByteBuffer.wrap(digest).getLong();
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    private static void advisoryLock(java.sql.Connection connection, long key, boolean acquire) throws SQLException {
        String function = acquire ? "pg_advisory_lock" : "pg_advisory_unlock";
        try (PreparedStatement statement = connection.prepareStatement("SELECT " + function + "(?)")) {
            statement.setLong(1, key);
            statement.execute();
        }
    }
}
