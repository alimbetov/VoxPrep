package io.github.alimbetov.voxprep.backend.content.dev;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import io.github.alimbetov.voxprep.backend.content.application.ContentAuthoringService;
import io.github.alimbetov.voxprep.backend.content.application.ContentDraftUpdate;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;
import tools.jackson.databind.ObjectMapper;

/** DEV fixture parses and dispatches 32 Drafts, without requiring PostgreSQL. */
class DemoCatalogueSeedRunnerTest {
    @Test
    void generatedCatalogueCreatesOnlyDraftsThroughAuthoringService() throws Exception {
        var authoring = mock(ContentAuthoringService.class);
        var revisions = mock(ContentRevisionRepository.class);
        when(revisions.findIdByExactIdentity(anyString(), anyString(), eq(1)))
                .thenReturn(Optional.empty());
        var runner = new DemoCatalogueSeedRunner(authoring, revisions,
                new ObjectMapper(), new ClassPathResource("dev-fixtures/demo_catalogue_seed.json"));

        runner.run(null);

        verify(authoring, times(32)).createInitialRevision(any(BusinessCode.class),
                any(ContentDraftUpdate.class));
        verifyNoMoreInteractions(authoring);
    }

    @Test
    void rerunLeavesPreviouslyImportedDraftsUntouched() throws Exception {
        var authoring = mock(ContentAuthoringService.class);
        var revisions = mock(ContentRevisionRepository.class);
        when(revisions.findIdByExactIdentity(anyString(), anyString(), eq(1)))
                .thenReturn(Optional.of(UUID.randomUUID()));
        var runner = new DemoCatalogueSeedRunner(authoring, revisions,
                new ObjectMapper(), new ClassPathResource("dev-fixtures/demo_catalogue_seed.json"));

        runner.run(null);

        verifyNoInteractions(authoring);
    }

    @Test
    void fixtureHasStablePublicProductIdentityButDoesNotGrantEntitlement() throws Exception {
        var resource = new ClassPathResource("dev-fixtures/demo_catalogue_seed.json");
        try (var input = resource.getInputStream()) {
            var root = new ObjectMapper().readValue(input, java.util.Map.class);
            assertThat(root.get("fixture")).isEqualTo("voxprep-dev-test");
            assertThat(root.get("productId")).isEqualTo("voxprep_full_unlock");
            assertThat((java.util.List<?>) root.get("items")).hasSize(32);
            assertThat(root).doesNotContainKeys("purchaseToken", "entitlement");
        }
    }
}
