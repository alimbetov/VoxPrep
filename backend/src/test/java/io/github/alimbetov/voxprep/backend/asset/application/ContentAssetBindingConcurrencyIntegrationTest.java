package io.github.alimbetov.voxprep.backend.asset.application;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.alimbetov.voxprep.backend.asset.domain.ContentAssetRole;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.ContentAssetBindingRepository;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.PhraseContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@ActiveProfiles("test")
@SpringBootTest
class ContentAssetBindingConcurrencyIntegrationTest {

    @Autowired private ContentAssetBindingService bindings;
    @Autowired private ContentAssetBindingRepository bindingRepository;
    @Autowired private ContentRevisionRepository revisions;
    @Autowired private FileAssetRepository assets;

    @Test
    void concurrentInsertForSameContentAndRoleKeepsExactlyOneValidBinding() throws Exception {
        var contentId = contentRevision();
        var first = cover();
        var second = cover();

        try (var workers = Executors.newFixedThreadPool(2)) {
            var start = new CountDownLatch(1);
            var a = workers.submit(() -> {
                start.await();
                return bindings.bind(contentId, ContentAssetRole.COVER_IMAGE, first, null);
            });
            var b = workers.submit(() -> {
                start.await();
                return bindings.bind(contentId, ContentAssetRole.COVER_IMAGE, second, null);
            });
            start.countDown();
            a.get(20, TimeUnit.SECONDS);
            b.get(20, TimeUnit.SECONDS);
        }

        var persisted = bindingRepository.findAllByContentRevision_IdOrderByRoleAsc(contentId);
        assertThat(persisted).hasSize(1);
        assertThat(Set.of(first, second)).contains(persisted.getFirst().getFileAsset().getId());
    }

    @Test
    void concurrentReplacementOfExistingBindingKeepsSingleRow() throws Exception {
        var contentId = contentRevision();
        var original = cover();
        var firstReplacement = cover();
        var secondReplacement = cover();
        bindings.bind(contentId, ContentAssetRole.COVER_IMAGE, original, null);

        try (var workers = Executors.newFixedThreadPool(2)) {
            var start = new CountDownLatch(1);
            var a = workers.submit(() -> {
                start.await();
                return bindings.bind(contentId, ContentAssetRole.COVER_IMAGE, firstReplacement, null);
            });
            var b = workers.submit(() -> {
                start.await();
                return bindings.bind(contentId, ContentAssetRole.COVER_IMAGE, secondReplacement, null);
            });
            start.countDown();
            a.get(20, TimeUnit.SECONDS);
            b.get(20, TimeUnit.SECONDS);
        }

        var persisted = bindingRepository.findAllByContentRevision_IdOrderByRoleAsc(contentId);
        assertThat(persisted).hasSize(1);
        assertThat(Set.of(firstReplacement, secondReplacement))
                .contains(persisted.getFirst().getFileAsset().getId());
        assertThat(persisted.getFirst().getFileAsset().getId()).isNotEqualTo(original);
    }

    private UUID contentRevision() {
        return revisions.saveAndFlush(new PhraseContentRevisionEntity(
                new BusinessCode("H1_BIND_" + UUID.randomUUID()),
                new RevisionNumber(1), new Sha256Digest("a".repeat(64)),
                "Title", "Subtitle", "Description",
                new CatalogueCode("GENERAL"), new CatalogueCode("B1"), 1,
                List.of(new CatalogueCode("SPEAKING")), AvailabilityStatus.ACTIVE,
                "Example phrase", "Usage", List.of("Example"))).getId();
    }

    private UUID cover() {
        return assets.saveAndFlush(new FileAssetEntity(
                FileAssetKind.COVER_IMAGE, FileAssetStatus.READY,
                "voxprep-assets", "h1/" + UUID.randomUUID() + ".png",
                "image/png", 10, "b".repeat(64))).getId();
    }
}
