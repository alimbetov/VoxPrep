package io.github.alimbetov.voxprep.backend.content.localization;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.application.ContentAuthoringConflictException;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.VocabularyContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@ActiveProfiles("test")
@SpringBootTest
class ContentLocalizationConcurrencyIntegrationTest {

    @Autowired private ContentRevisionRepository contents;
    @Autowired private ContentLocalizationAuthoringService service;

    @Test
    void parallelCreatesAllocateDistinctSequentialRevisionNumbers() throws Exception {
        UUID contentId = contents.saveAndFlush(vocabulary()).getId();
        try (var workers = Executors.newFixedThreadPool(2)) {
            var start = new CountDownLatch(1);
            Future<ContentLocalizationAuthoringService.Snapshot> first =
                    workers.submit(() -> {
                        start.await();
                        return create(contentId, "First");
                    });
            Future<ContentLocalizationAuthoringService.Snapshot> second =
                    workers.submit(() -> {
                        start.await();
                        return create(contentId, "Second");
                    });
            start.countDown();
            var results = List.of(first.get(20, TimeUnit.SECONDS), second.get(20, TimeUnit.SECONDS));
            assertThat(results).extracting(ContentLocalizationAuthoringService.Snapshot::localizationRevisionNumber)
                    .containsExactlyInAnyOrder(1, 2);
            assertThat(results).extracting(ContentLocalizationAuthoringService.Snapshot::id)
                    .doesNotHaveDuplicates();
            assertThat(service.listByContent(contentId)).hasSize(2);
        }
    }

    @Test
    void parallelCreateNextAllowsExactlyOneSuccess() throws Exception {
        UUID contentId = contents.saveAndFlush(vocabulary()).getId();
        var draft = create(contentId, "Original");
        var review = service.submitForReview(draft.id(), draft.version(), "reviewer", "review", null);
        var approved = service.approve(review.id(), review.version(), "approver", "approve", null);

        try (var workers = Executors.newFixedThreadPool(2)) {
            var start = new CountDownLatch(1);
            Future<Object> first = workers.submit(() -> createNextResult(approved, start));
            Future<Object> second = workers.submit(() -> createNextResult(approved, start));
            start.countDown();
            Object a = first.get(20, TimeUnit.SECONDS);
            Object b = second.get(20, TimeUnit.SECONDS);
            assertThat(List.of(a, b).stream()
                    .filter(value -> value instanceof ContentLocalizationAuthoringService.Snapshot)
                    .count()).isEqualTo(1);
            assertThat(List.of(a, b).stream()
                    .filter(value -> value instanceof ContentAuthoringConflictException)
                    .count()).isEqualTo(1);
        }
        var revisions = service.listByContent(contentId);
        assertThat(revisions).hasSize(2);
        assertThat(revisions).extracting(ContentLocalizationAuthoringService.Snapshot::localizationRevisionNumber)
                .containsExactlyInAnyOrder(1, 2);
    }

    private Object createNextResult(
            ContentLocalizationAuthoringService.Snapshot approved, CountDownLatch start) throws Exception {
        start.await();
        try {
            return service.createNext(approved.id(), approved.version());
        } catch (ContentAuthoringConflictException exception) {
            return exception;
        }
    }

    private ContentLocalizationAuthoringService.Snapshot create(UUID contentId, String title) {
        return service.create(contentId, "kk-KZ", new Sha256Digest("a".repeat(64)),
                new ContentLocalizationAuthoringService.Fields(title, null, null, null, null, null));
    }

    private static VocabularyContentRevisionEntity vocabulary() {
        return new VocabularyContentRevisionEntity(
                new BusinessCode("h1-localization-" + UUID.randomUUID()),
                new RevisionNumber(1),
                new Sha256Digest("a".repeat(64)),
                "Concurrency title", "Subtitle", "Description",
                new CatalogueCode("VOCABULARY"), new CatalogueCode("B2"),
                4, List.of(new CatalogueCode("SPEAKING")),
                AvailabilityStatus.ACTIVE, "negotiate", "definition", "verb", List.of("Example"));
    }
}
