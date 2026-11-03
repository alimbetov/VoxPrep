package io.github.alimbetov.voxprep.backend.learner.application;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import io.github.alimbetov.voxprep.backend.content.domain.ContentRevisionIdentity;
import io.github.alimbetov.voxprep.backend.content.domain.ContentType;
import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;

class LearnerCatalogueServiceTest {

    private static final String A = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    private static final String B = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";

    @Test
    void exposesOnlyExactRefsFromCurrentPublicationInManifestOrder() {
        CurrentPublicationResolver resolver = mock(CurrentPublicationResolver.class);
        PublicationExactContentRef first = ref("alpha", ContentType.VOCABULARY, 2, A);
        PublicationExactContentRef second = ref("beta", ContentType.QUESTION, 4, B);
        Instant publishedAt = Instant.parse("2026-11-03T10:00:00Z");

        when(resolver.resolve()).thenReturn(new CurrentPublicationSnapshot(
                17L,
                A,
                publishedAt,
                List.of(first, second)));

        LearnerCatalogueSnapshot result = new LearnerCatalogueService(resolver).getCurrentCatalogue();

        assertEquals(17L, result.contentVersion());
        assertEquals(A, result.rootSha256());
        assertEquals(publishedAt, result.publishedAt());
        assertEquals(List.of(
                new LearnerCatalogueEntry("alpha", "vocabulary", 2, A),
                new LearnerCatalogueEntry("beta", "question", 4, B)),
                result.entries());
    }

    private static PublicationExactContentRef ref(
            String code, ContentType type, int revision, String checksum) {
        return new PublicationExactContentRef(
                new ContentRevisionIdentity(new BusinessCode(code), type, new RevisionNumber(revision)),
                new Sha256Digest(checksum));
    }
}
