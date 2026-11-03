package io.github.alimbetov.voxprep.backend.installation.application;

import io.github.alimbetov.voxprep.backend.installation.persistence.InstallationEntity;
import io.github.alimbetov.voxprep.backend.installation.persistence.InstallationRepository;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Clock;
import java.util.Base64;
import java.util.HexFormat;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class InstallationRegistrationService {

    private static final int TOKEN_BYTES = 32;

    private final InstallationRepository repository;
    private final SecureRandom secureRandom;
    private final Clock clock;

    public InstallationRegistrationService(InstallationRepository repository) {
        this(repository, new SecureRandom(), Clock.systemUTC());
    }

    InstallationRegistrationService(
            InstallationRepository repository,
            SecureRandom secureRandom,
            Clock clock) {
        this.repository = repository;
        this.secureRandom = secureRandom;
        this.clock = clock;
    }

    @Transactional
    public RegistrationResult register(UUID installationId) {
        var token = generateToken();
        var tokenSha256 = sha256(token);
        var issuedAt = clock.instant();

        var installation = repository.findByInstallationId(installationId)
                .map(existing -> {
                    existing.rotateToken(tokenSha256, issuedAt);
                    return existing;
                })
                .orElseGet(() -> new InstallationEntity(installationId, tokenSha256, issuedAt));

        repository.save(installation);
        return new RegistrationResult(installationId, token, issuedAt);
    }

    private String generateToken() {
        byte[] bytes = new byte[TOKEN_BYTES];
        secureRandom.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private static String sha256(String value) {
        try {
            var digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 must be available", exception);
        }
    }

    public record RegistrationResult(UUID installationId, String installationToken, java.time.Instant issuedAt) {
    }
}
