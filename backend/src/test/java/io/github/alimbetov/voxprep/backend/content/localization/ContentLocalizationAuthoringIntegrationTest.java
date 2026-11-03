package io.github.alimbetov.voxprep.backend.content.localization;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.VocabularyContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

@ActiveProfiles("test")
@SpringBootTest
class ContentLocalizationAuthoringIntegrationTest {

    @Autowired private ContentRevisionRepository contentRepository;
    @Autowired private ContentLocalizationRevisionRepository localizationRepository;
    @Autowired private ContentLocalizationAuthoringService service;
    @Autowired private JdbcTemplate jdbcTemplate;

    @Test
    void localizationRevisionChainIsImmutableReviewedAndAudited() {
        var canonical = contentRepository.saveAndFlush(new VocabularyContentRevisionEntity(
                new BusinessCode("localization-" + UUID.randomUUID()),
                new RevisionNumber(1),
                new Sha256Digest("a".repeat(64)),
                "Canonical title",
                "Canonical subtitle",
                "Canonical description",
                new CatalogueCode("VOCABULARY"),
                new CatalogueCode("B2"),
                4,
                List.of(new CatalogueCode("SPEAKING")),
                AvailabilityStatus.ACTIVE,
                "negotiate",
                "to discuss in order to reach agreement",
                "verb",
                List.of("Example")));

        var created = service.create(
                canonical.getId(),
                "ru-kz",
                new Sha256Digest("b".repeat(64)),
                new ContentLocalizationAuthoringService.Fields(
                        "Локальный заголовок", null, null, "перевод", null, null));
        assertThat(created.locale()).isEqualTo("ru-KZ");
        assertThat(created.localizationRevisionNumber()).isEqualTo(1);
        assertThat(created.lifecycle()).isEqualTo(ContentLocalizationLifecycleStatus.DRAFT);

        var updated = service.updateDraft(
                created.id(),
                created.version(),
                new Sha256Digest("c".repeat(64)),
                new ContentLocalizationAuthoringService.Fields(
                        "Обновленный заголовок", null, null, "перевод", "подсказка", null));
        var reviewed = service.submitForReview(
                updated.id(), updated.version(), "admin", "LOCALIZATION_REVIEW", "checked");
        var approved = service.approve(
                reviewed.id(), reviewed.version(), "admin", "LOCALIZATION_APPROVAL", "approved");

        assertThat(approved.lifecycle()).isEqualTo(ContentLocalizationLifecycleStatus.APPROVED);
        assertThat(approved.approvedAt()).isNotNull();

        var next = service.createNext(approved.id(), approved.version());
        assertThat(next.localizationRevisionNumber()).isEqualTo(2);
        assertThat(next.lifecycle()).isEqualTo(ContentLocalizationLifecycleStatus.DRAFT);

        assertThat(localizationRepository
                        .findAllByContentRevisionIdAndLocaleOrderByLocalizationRevisionNumberAsc(canonical.getId(), "ru-KZ"))
                .hasSize(2);

        Integer auditCount = jdbcTemplate.queryForObject(
                "select count(*) from app.content_localization_review_audit where localization_revision_id = ?",
                Integer.class,
                approved.id());
        assertThat(auditCount).isEqualTo(2);

        assertThatThrownBy(() -> jdbcTemplate.update(
                        "update app.content_localization_review_audit set actor = 'tampered' where localization_revision_id = ?",
                        approved.id()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }
}
