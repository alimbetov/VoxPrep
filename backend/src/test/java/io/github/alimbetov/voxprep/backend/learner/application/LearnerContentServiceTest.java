package io.github.alimbetov.voxprep.backend.learner.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.application.ContentRevisionSnapshot;
import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.TopicContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.TopicSectionEmbeddable;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class LearnerContentServiceTest {

    private static final String ROOT = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    private static final String CHECKSUM = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";

    private CurrentPublicationResolver currentPublicationResolver;
    private ContentRevisionRepository contentRevisionRepository;
    private LearnerContentService service;

    @BeforeEach
    void setUp() {
        currentPublicationResolver = mock(CurrentPublicationResolver.class);
        contentRevisionRepository = mock(ContentRevisionRepository.class);
        service = new LearnerContentService(currentPublicationResolver, contentRevisionRepository);
    }

    @Test
    void resolvesExactRevisionFromCurrentPublicationAndReturnsLearnerSafeSnapshot() {
        PublicationExactContentRef ref = ref(ContentType.TOPIC, "topic-1", 3, CHECKSUM);
        TopicContentRevisionEntity revision = topic("topic-1", 3, CHECKSUM);
        when(currentPublicationResolver.resolve()).thenReturn(publication(ref));
        when(contentRevisionRepository.findExact(ref.identity())).thenReturn(Optional.of(revision));

        LearnerContentSnapshot result = service.get("topic", "topic-1");

        assertThat(result.contentVersion()).isEqualTo(11L);
        assertThat(result.rootSha256()).isEqualTo(ROOT);
        assertThat(result.contentCode()).isEqualTo("topic-1");
        assertThat(result.contentType()).isEqualTo("topic");
        assertThat(result.revisionNumber()).isEqualTo(3);
        assertThat(result.checksumSha256()).isEqualTo(CHECKSUM);
        assertThat(result.body()).isInstanceOf(ContentRevisionSnapshot.TopicBody.class);
    }

    @Test
    void refusesContentThatIsNotInCurrentPublication() {
        PublicationExactContentRef ref = ref(ContentType.TOPIC, "other", 1, CHECKSUM);
        when(currentPublicationResolver.resolve()).thenReturn(publication(ref));

        assertThatThrownBy(() -> service.get("topic", "topic-1"))
                .isInstanceOf(LearnerContentNotFoundException.class)
                .hasMessage("published learner content not found: topic/topic-1");
        verify(contentRevisionRepository, never()).findExact(ref.identity());
    }

    @Test
    void failsClosedWhenStoredRevisionChecksumDiffersFromManifest() {
        PublicationExactContentRef ref = ref(ContentType.TOPIC, "topic-1", 3, CHECKSUM);
        TopicContentRevisionEntity revision = topic(
                "topic-1",
                3,
                "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc");
        when(currentPublicationResolver.resolve()).thenReturn(publication(ref));
        when(contentRevisionRepository.findExact(ref.identity())).thenReturn(Optional.of(revision));

        assertThatThrownBy(() -> service.get("topic", "topic-1"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("published content checksum differs from publication manifest");
    }

    @Test
    void assessmentTypesCannotLeakThroughGenericContentEndpoint() {
        assertThatThrownBy(() -> service.get("question", "question-1"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("assessment content must be requested through the learner assessment API");
        verify(currentPublicationResolver, never()).resolve();
    }

    private static CurrentPublicationSnapshot publication(PublicationExactContentRef ref) {
        return new CurrentPublicationSnapshot(
                11L,
                ROOT,
                Instant.parse("2026-11-03T11:00:00Z"),
                List.of(ref));
    }

    private static PublicationExactContentRef ref(
            ContentType type,
            String code,
            int revision,
            String checksum) {
        return new PublicationExactContentRef(
                new ContentRevisionIdentity(
                        new BusinessCode(code),
                        type,
                        new RevisionNumber(revision)),
                new Sha256Digest(checksum));
    }

    private static TopicContentRevisionEntity topic(String code, int revision, String checksum) {
        return new TopicContentRevisionEntity(
                new BusinessCode(code),
                new RevisionNumber(revision),
                new Sha256Digest(checksum),
                "Topic title",
                "Topic subtitle",
                "Topic description",
                new CatalogueCode("CATEGORY"),
                new CatalogueCode("B1"),
                5,
                List.of(new CatalogueCode("SPEAKING")),
                AvailabilityStatus.ACTIVE,
                List.of(new TopicSectionEmbeddable("Heading", "Body")));
    }
}
