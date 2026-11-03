package io.github.alimbetov.voxprep.backend.installation.persistence;

import io.github.alimbetov.voxprep.backend.infrastructure.persistence.AbstractJpaEntity;
import io.github.alimbetov.voxprep.backend.installation.domain.InstallationStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

@Entity
@Table(
        name = "installation",
        schema = "app",
        uniqueConstraints = {
            @UniqueConstraint(name = "uk_installation__installation_id", columnNames = "installation_id"),
            @UniqueConstraint(name = "uk_installation__token_sha256", columnNames = "token_sha256")
        })
public class InstallationEntity extends AbstractJpaEntity {

    @Column(name = "installation_id", nullable = false, updatable = false)
    private UUID installationId;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 32)
    private InstallationStatus status;

    @Column(name = "token_sha256", nullable = false, length = 64)
    private String tokenSha256;

    @Column(name = "token_issued_at", nullable = false)
    private Instant tokenIssuedAt;

    protected InstallationEntity() {
    }

    public InstallationEntity(UUID installationId, String tokenSha256, Instant tokenIssuedAt) {
        this.installationId = Objects.requireNonNull(installationId, "installationId");
        this.status = InstallationStatus.ACTIVE;
        rotateToken(tokenSha256, tokenIssuedAt);
    }

    public void rotateToken(String tokenSha256, Instant tokenIssuedAt) {
        if (status != InstallationStatus.ACTIVE) {
            throw new IllegalStateException("Only ACTIVE installation may rotate token");
        }
        this.tokenSha256 = requireSha256(tokenSha256);
        this.tokenIssuedAt = Objects.requireNonNull(tokenIssuedAt, "tokenIssuedAt");
    }

    public UUID getInstallationId() {
        return installationId;
    }

    public InstallationStatus getStatus() {
        return status;
    }

    public String getTokenSha256() {
        return tokenSha256;
    }

    public Instant getTokenIssuedAt() {
        return tokenIssuedAt;
    }

    private static String requireSha256(String value) {
        Objects.requireNonNull(value, "tokenSha256");
        if (!value.matches("[0-9a-f]{64}")) {
            throw new IllegalArgumentException("tokenSha256 must be lowercase SHA-256");
        }
        return value;
    }
}
