package io.github.alimbetov.voxprep.backend.infrastructure.persistence;

import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.StableCode;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;

@Entity
@Table(name = "persistence_foundation_probe", schema = "app")
public class PersistenceFoundationProbeEntity extends AbstractJpaEntity {

    @Column(name = "stable_code", nullable = false, updatable = false, length = StableCode.MAX_LENGTH)
    private String stableCode;

    @Enumerated(EnumType.STRING)
    @Column(name = "availability", nullable = false, length = 16)
    private AvailabilityStatus availability;

    @Column(name = "payload", nullable = false, length = 255)
    private String payload;

    protected PersistenceFoundationProbeEntity() {
    }

    public PersistenceFoundationProbeEntity(
            StableCode stableCode,
            AvailabilityStatus availability,
            String payload) {
        this.stableCode = stableCode.value();
        this.availability = availability;
        this.payload = payload;
    }

    public String getStableCode() {
        return stableCode;
    }

    public AvailabilityStatus getAvailability() {
        return availability;
    }

    public String getPayload() {
        return payload;
    }

    public void updatePayload(String payload) {
        this.payload = payload;
    }

    public void changeAvailability(AvailabilityStatus availability) {
        this.availability = availability;
    }
}
