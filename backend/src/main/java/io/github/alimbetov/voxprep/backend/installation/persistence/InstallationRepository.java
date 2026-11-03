package io.github.alimbetov.voxprep.backend.installation.persistence;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InstallationRepository extends JpaRepository<InstallationEntity, UUID> {
    Optional<InstallationEntity> findByInstallationId(UUID installationId);
    Optional<InstallationEntity> findByTokenSha256(String tokenSha256);
}
