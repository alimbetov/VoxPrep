package io.github.alimbetov.voxprep.backend.publication.application;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.PhraseContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@ActiveProfiles("test")
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Transactional
class JpaPublicationContentFreezerIntegrationTest {

    @Autowired private PublicationContentFreezer contentFreezer;
    @Autowired private ContentRevisionRepository contentRevisionRepository;

    @Test
    void approvedExactRevisionBecomesPublishedAtReleaseBoundary() {
        var revision = contentRevisionRepository.saveAndFlush(new PhraseContentRevisionEntity(
                new BusinessCode("R5_FREEZE"),
                new RevisionNumber(1),
                new Sha256Digest(String.valueOf('7').repeat(64)),
                "Title",
                "Subtitle",
                "Description",
                new CatalogueCode("GENERAL"),
                new CatalogueCode("B1"),
                1,
                List.of(new CatalogueCode("SPEAKING")),
                AvailabilityStatus.ACTIVE,
                "Could you tell me more?",
                "Usage",
                List.of("Example")));
        revision.markReadyForAudio();
        revision.markReadyForReview();
        revision.approve(Instant.parse("2026-11-03T12:00:00Z"));
        contentRevisionRepository.saveAndFlush(revision);
        PublicationExactContentRef ref = new PublicationExactContentRef(revision.getIdentity(), revision.getChecksum());
        Instant publishedAt = Instant.parse("2026-11-03T13:00:00Z");

        contentFreezer.freeze(List.of(ref), publishedAt);
        contentRevisionRepository.flush();

        var frozen = contentRevisionRepository.findById(revision.getId()).orElseThrow();
        assertThat(frozen.getLifecycle()).isEqualTo(ContentLifecycleStatus.PUBLISHED);
        assertThat(frozen.getPublishedAt()).isEqualTo(publishedAt);
    }
}
