package io.github.alimbetov.voxprep.backend.installation.security;

import io.github.alimbetov.voxprep.backend.installation.domain.InstallationStatus;
import io.github.alimbetov.voxprep.backend.installation.persistence.InstallationRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class InstallationAuthenticationService {

    private final InstallationRepository repository;

    public InstallationAuthenticationService(InstallationRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public InstallationPrincipal authenticate(String token) {
        if (token == null || token.isBlank()) {
            throw new InstallationAuthenticationException("INSTALLATION_TOKEN_MISSING", "Installation token is required");
        }

        var tokenSha256 = InstallationTokenHasher.sha256(token);
        var installation = repository.findByTokenSha256(tokenSha256)
                .orElseThrow(() -> new InstallationAuthenticationException(
                        "INSTALLATION_TOKEN_INVALID",
                        "Installation token is invalid"));

        if (installation.getStatus() == InstallationStatus.BLOCKED) {
            throw new InstallationAuthenticationException(
                    "INSTALLATION_BLOCKED",
                    "Installation is blocked");
        }
        if (installation.getStatus() == InstallationStatus.REVOKED) {
            throw new InstallationAuthenticationException(
                    "INSTALLATION_REVOKED",
                    "Installation is revoked");
        }

        return new InstallationPrincipal(installation.getInstallationId());
    }
}
