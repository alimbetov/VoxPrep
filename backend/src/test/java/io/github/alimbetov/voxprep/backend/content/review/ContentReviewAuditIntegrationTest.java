package io.github.alimbetov.voxprep.backend.content.review;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.application.ContentAuthoringService;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.VocabularyContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

@ActiveProfiles("test")
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ContentReviewAuditIntegrationTest {

    @Autowired
    private ContentRevisionRepository contentRepository;

    @Autowired
    private ContentReviewAuditRepository auditRepository;

    @Autowired
    private ContentAuthoringService authoringService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void reviewAndApprovalCreateOrderedAppendOnlyAudit() {
        var revision = contentRepository.saveAndFlush(new VocabularyContentRevisionEntity(
                new BusinessCode("review-audit-" + UUID.randomUUID()),
                new RevisionNumber(1),
                new Sha256Digest("a".repeat(64)),
                "Vocabulary title",
                "Vocabulary subtitle",
                "Vocabulary description",
                new CatalogueCode("VOCABULARY"),
                new CatalogueCode("B2"),
                4,
                List.of(new CatalogueCode("SPEAKING")),
                AvailabilityStatus.ACTIVE,
                "negotiate",
                "to discuss in order to reach agreement",
                "verb",
                List.of("Example one")));

        authoringService.markReadyForAudio(revision.getId());
        authoringService.submitForReview(
                revision.getId(),
                "admin",
                "READY_FOR_EDITORIAL_REVIEW",
                "Language and structure checked");

        var approvedAt = Instant.parse("2026-11-03T04:00:00Z");
        authoringService.approve(
                revision.getId(),
                approvedAt,
                "senior-admin",
                "EDITORIAL_APPROVAL",
                "Approved for publication candidate generation");

        var audit = auditRepository.findAllByContentRevisionIdOrderByOccurredAtAscIdAsc(revision.getId());
        assertThat(audit).hasSize(2);
        assertThat(audit.get(0).getAction()).isEqualTo(ContentReviewAction.SUBMITTED_FOR_REVIEW);
        assertThat(audit.get(0).getActor()).isEqualTo("admin");
        assertThat(audit.get(0).getReason()).isEqualTo("READY_FOR_EDITORIAL_REVIEW");
        assertThat(audit.get(1).getAction()).isEqualTo(ContentReviewAction.APPROVED);
        assertThat(audit.get(1).getActor()).isEqualTo("senior-admin");
        assertThat(audit.get(1).getOccurredAt()).isEqualTo(approvedAt);

        UUID auditId = audit.get(0).getId();
        assertThatThrownBy(() -> jdbcTemplate.update(
                        "update app.content_review_audit set actor = 'tampered' where id = ?",
                        auditId))
                .isInstanceOf(DataIntegrityViolationException.class);

        assertThatThrownBy(() -> jdbcTemplate.update(
                        "delete from app.content_review_audit where id = ?",
                        auditId))
                .isInstanceOf(DataIntegrityViolationException.class);
    }
}
