package io.github.alimbetov.voxprep.backend.installation.application;

import io.github.alimbetov.voxprep.backend.installation.persistence.InstallationEntity;
import io.github.alimbetov.voxprep.backend.installation.persistence.InstallationRepository;
import io.github.alimbetov.voxprep.backend.installation.security.InstallationTokenHasher;
import java.security.SecureRandom;
import java.time.Clock;
import java.util.Base64;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class InstallationRegistrationService {

    private static final int TOKEN_BYTES = 32;

    private final InstallationRepository repository;
    private final JdbcTemplate jdbcTemplate;
    private final SecureRandom secureRandom;
    private final Clock clock;

    @Autowired
    public InstallationRegistrationService(
            InstallationRepository repository,
            JdbcTemplate jdbcTemplate) {
        this(repository, jdbcTemplate, new SecureRandom(), Clock.systemUTC());
    }

    InstallationRegistrationService(
            InstallationRepository repository,
            JdbcTemplate jdbcTemplate,
            SecureRandom secureRandom,
            Clock clock) {
        this.repository = repository;
        this.jdbcTemplate = jdbcTemplate;
        this.secureRandom = secureRandom;
        this.clock = clock;
    }

    @Transactional
    public RegistrationResult register(UUID installationId) {
        serializeRegistration(installationId);

        String token = generateToken();
        String tokenSha256 = InstallationTokenHasher.sha256(token);
        var issuedAt = clock.instant();

        InstallationEntity installation = repository.findByInstallationId(installationId).orElse(null);
        if (installation == null) {
            installation = new InstallationEntity(installationId, tokenSha256, issuedAt);
        } else {
            installation.rotateToken(tokenSha256, issuedAt);
        }

        repository.save(installation);
        return new RegistrationResult(installationId, token, issuedAt);
    }

    private void serializeRegistration(UUID installationId) {
        jdbcTemplate.execute((ConnectionCallback<Void>) connection -> {
            try (var statement = connection.prepareStatement(
                    "select pg_advisory_xact_lock(hashtextextended(?::text, 0))")) {
                statement.setString(1, installationId.toString());
                statement.execute();
                return null;
            }
        });
    }

    private String generateToken() {
        byte[] bytes = new byte[TOKEN_BYTES];
        secureRandom.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    public record RegistrationResult(UUID installationId, String installationToken, java.time.Instant issuedAt) {
    }
}
