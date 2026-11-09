package io.github.alimbetov.voxprep.backend.asset.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.PhraseContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@ActiveProfiles("test")
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Transactional
class ExternalLearningVideoIntegrationTest {
    @Autowired private ContentRevisionRepository revisions;
    @Autowired private ExternalLearningVideoService videos;
    @Autowired private JdbcTemplate jdbc;

    @Test
    void revisionPublishesImmutableSnapshotWithoutChangingTextOrMedia() {
        var revision = revisions.saveAndFlush(new PhraseContentRevisionEntity(
                new BusinessCode("EV_" + UUID.randomUUID().toString().replace("-", "")),
                new RevisionNumber(1),
                new Sha256Digest("a".repeat(64)),
                "Practice", "Listening", "Professional English",
                new CatalogueCode("COMMUNICATION"), new CatalogueCode("B1"), 2,
                List.of(new CatalogueCode("SPEAKING")), AvailabilityStatus.ACTIVE,
                "Could you clarify?", "At work", List.of("Could you clarify the scope?")));
        UUID id = revision.getId();
        assertThat(videos.find(id)).isEmpty();
        assertThat(videos.findPublished(id)).isEmpty();
        videos.save(id, "https://youtu.be/AbCdEfGh123", "Educational video");
        assertThat(videos.find(id)).get().extracting(
                ExternalLearningVideoService.Video::providerVideoId).isEqualTo("AbCdEfGh123");
        assertThat(videos.findPublished(id)).isEmpty();

        revision.markReadyForAudio();
        revisions.saveAndFlush(revision);
        revision.markReadyForReview();
        revisions.saveAndFlush(revision);
        revision.approve(Instant.parse("2026-11-08T10:00:00Z"));
        revisions.saveAndFlush(revision);
        revision.publish(Instant.parse("2026-11-08T10:01:00Z"));
        revisions.saveAndFlush(revision);

        var frozen = videos.findPublished(id).orElseThrow();
        assertThat(frozen.provider()).isEqualTo("YOUTUBE");
        assertThat(frozen.providerVideoId()).isEqualTo("AbCdEfGh123");
        assertThat(frozen.url()).isEqualTo("https://www.youtube.com/watch?v=AbCdEfGh123");
        assertThatThrownBy(() -> videos.save(id,
                "https://youtu.be/AbCdEfGh123", "Unauthorized change"))
                .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> videos.remove(id)).isInstanceOf(IllegalStateException.class);
        assertThat(videos.findPublished(id)).contains(frozen);
        // Even bypassing Java services, SQL cannot modify the frozen publication reference.
        assertThatThrownBy(() -> jdbc.update(
                "UPDATE app.content_external_video_snapshot SET title=? WHERE content_revision_id=?",
                "tampered", id))
                .isInstanceOf(DataAccessException.class);
    }

    @Test
    void draftVideoCanBeRemovedWithoutCreatingAnyPublishedReference() {
        var revision = revisions.saveAndFlush(new PhraseContentRevisionEntity(
                new BusinessCode("EV_" + UUID.randomUUID().toString().replace("-", "")),
                new RevisionNumber(1), new Sha256Digest("b".repeat(64)),
                "Title", "Subtitle", "Description",
                new CatalogueCode("COMMUNICATION"), new CatalogueCode("B1"), 2,
                List.of(new CatalogueCode("SPEAKING")), AvailabilityStatus.ACTIVE,
                "Hello", "Usage", List.of("Hello world")));
        UUID id = revision.getId();
        videos.save(id, "https://www.youtube.com/watch?v=AbCdEfGh123", "Lesson");
        videos.remove(id);
        assertThat(videos.find(id)).isEmpty();
        assertThat(videos.findPublished(id)).isEmpty();
    }
}
