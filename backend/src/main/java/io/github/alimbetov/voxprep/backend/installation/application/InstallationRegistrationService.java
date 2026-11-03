package io.github.alimbetov.voxprep.backend.installation.application;

import io.github.alimbetov.voxprep.backend.installation.persistence.InstallationEntity;
import io.github.alimbetov.voxprep.backend.installation.persistence.InstallationRepository;
import io.github.alimbetov.voxprep.backend.installation.domain.InstallationStatus;
import io.github.alimbetov.voxprep.backend.installation.security.InstallationAuthenticationException;
import io.github.alimbetov.voxprep.backend.installation.security.InstallationTokenHasher;
import java.security.SecureRandom;
import java.security.MessageDigest;
import java.nio.charset.StandardCharsets;
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

    /**
     * Initial registration accepts an unclaimed, random installation UUID.
     * Every subsequent rotation requires proof of the *current* Bearer credential.
     * The advisory transaction lock serializes rotations across backend instances.
     */
    @Transactional
    public RegistrationResult register(UUID installationId, String authorization) {
        if (installationId == null) {
            throw new IllegalArgumentException("installationId must not be null");
        }
        serializeRegistration(installationId);

        InstallationEntity installation = repository.findByInstallationId(installationId).orElse(null);
        if (installation == null) {
            if (authorization != null) {
                throw unauthorized();
            }
        } else {
            requireRotationProof(installation, authorization);
        }

        String token = generateToken();
        String tokenSha256 = InstallationTokenHasher.sha256(token);
        var issuedAt = clock.instant();

        if (installation == null) {
            installation = new InstallationEntity(installationId, tokenSha256, issuedAt);
        } else {
            installation.rotateToken(tokenSha256, issuedAt);
        }
        repository.save(installation);
        return new RegistrationResult(installationId, token, issuedAt);
    }

    private static void requireRotationProof(InstallationEntity installation, String authorization) {
        if (installation.getStatus() != InstallationStatus.ACTIVE
                || authorization == null
                || !authorization.startsWith("Bearer ")
                || authorization.length() > 256) {
            throw unauthorized();
        }
        String previous = authorization.substring(7);
        // 32 cryptographically random bytes encoded without Base64URL padding.
        if (!previous.matches("[A-Za-z0-9_-]{43}")) {
            throw unauthorized();
        }
        String presentedHash = InstallationTokenHasher.sha256(previous);
        if (!MessageDigest.isEqual(
                presentedHash.getBytes(StandardCharsets.US_ASCII),
                installation.getTokenSha256().getBytes(StandardCharsets.US_ASCII))) {
            throw unauthorized();
        }
    }

    private static InstallationAuthenticationException unauthorized() {
        // Do not reveal whether the requested UUID is already registered.
        return new InstallationAuthenticationException(
                "INSTALLATION_ROTATION_NOT_AUTHORIZED", "Installation credential is invalid or missing");
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
