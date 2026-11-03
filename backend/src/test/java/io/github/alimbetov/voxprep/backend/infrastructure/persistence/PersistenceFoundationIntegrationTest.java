package io.github.alimbetov.voxprep.backend.infrastructure.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.StableCode;
import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityManagerFactory;
import jakarta.persistence.OptimisticLockException;
import jakarta.persistence.RollbackException;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

@ActiveProfiles("test")
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class PersistenceFoundationIntegrationTest {

    @Autowired
    private EntityManagerFactory entityManagerFactory;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void jpaBasePersistsUuidVersionAuditAndStringEnum() {
        String stableCode = "foundation-" + UUID.randomUUID();
        UUID id = null;
        EntityManager entityManager = entityManagerFactory.createEntityManager();

        try {
            entityManager.getTransaction().begin();

            var entity = new PersistenceFoundationProbeEntity(
                    new StableCode(stableCode),
                    AvailabilityStatus.ACTIVE,
                    "initial");
            entityManager.persist(entity);
            entityManager.flush();

            id = entity.getId();
            Instant createdAt = entity.getCreatedAt();
            Instant firstUpdatedAt = entity.getUpdatedAt();

            assertThat(id).isNotNull();
            assertThat(entity.getVersion()).isZero();
            assertThat(createdAt).isNotNull();
            assertThat(firstUpdatedAt).isNotNull();

            entity.updatePayload("updated");
            entity.changeAvailability(AvailabilityStatus.INACTIVE);
            entityManager.flush();

            assertThat(entity.getVersion()).isEqualTo(1L);
            assertThat(entity.getCreatedAt()).isEqualTo(createdAt);
            assertThat(entity.getUpdatedAt()).isAfterOrEqualTo(firstUpdatedAt);

            entityManager.getTransaction().commit();

            var row = jdbcTemplate.queryForMap(
                    "select stable_code, availability, payload from app.persistence_foundation_probe where id = ?",
                    id);
            assertThat(row.get("stable_code")).isEqualTo(stableCode);
            assertThat(row.get("availability")).isEqualTo("INACTIVE");
            assertThat(row.get("payload")).isEqualTo("updated");
        } finally {
            if (entityManager.getTransaction().isActive()) {
                entityManager.getTransaction().rollback();
            }
            entityManager.close();
            if (id != null) {
                jdbcTemplate.update("delete from app.persistence_foundation_probe where id = ?", id);
            }
        }
    }

    @Test
    void staleJpaWriteIsRejectedByOptimisticLocking() {
        UUID id = persistProbe();
        EntityManager first = entityManagerFactory.createEntityManager();
        EntityManager second = entityManagerFactory.createEntityManager();

        try {
            first.getTransaction().begin();
            second.getTransaction().begin();

            var firstCopy = first.find(PersistenceFoundationProbeEntity.class, id);
            var staleCopy = second.find(PersistenceFoundationProbeEntity.class, id);

            firstCopy.updatePayload("first-writer");
            first.getTransaction().commit();

            staleCopy.updatePayload("stale-writer");
            assertThatThrownBy(() -> second.getTransaction().commit())
                    .isInstanceOfAny(RollbackException.class, OptimisticLockException.class);

            String persisted = jdbcTemplate.queryForObject(
                    "select payload from app.persistence_foundation_probe where id = ?",
                    String.class,
                    id);
            assertThat(persisted).isEqualTo("first-writer");
        } finally {
            rollbackIfActive(first);
            rollbackIfActive(second);
            first.close();
            second.close();
            jdbcTemplate.update("delete from app.persistence_foundation_probe where id = ?", id);
        }
    }

    private UUID persistProbe() {
        EntityManager entityManager = entityManagerFactory.createEntityManager();
        try {
            entityManager.getTransaction().begin();
            var entity = new PersistenceFoundationProbeEntity(
                    new StableCode("locking-" + UUID.randomUUID()),
                    AvailabilityStatus.ACTIVE,
                    "initial");
            entityManager.persist(entity);
            entityManager.getTransaction().commit();
            return entity.getId();
        } finally {
            rollbackIfActive(entityManager);
            entityManager.close();
        }
    }

    private static void rollbackIfActive(EntityManager entityManager) {
        if (entityManager.getTransaction().isActive()) {
            entityManager.getTransaction().rollback();
        }
    }
}
