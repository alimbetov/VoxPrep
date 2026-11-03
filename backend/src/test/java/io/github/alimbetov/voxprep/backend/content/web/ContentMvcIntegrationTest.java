package io.github.alimbetov.voxprep.backend.content.web;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.application.ContentAuthoringService;
import io.github.alimbetov.voxprep.backend.content.application.ContentDraftUpdate;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.VocabularyContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

@ActiveProfiles("test")
@SpringBootTest
class ContentMvcIntegrationTest {

    @Autowired private WebApplicationContext context;
    @Autowired private ContentRevisionRepository repository;
    @Autowired private ContentAuthoringService authoring;
    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .apply(springSecurity())
                .build();
    }

    @Test
    void adminCanListOpenAndUpdateVocabularyDraft() throws Exception {
        var revision = repository.saveAndFlush(vocabulary());
        var initialVersion = revision.getVersion();

        mockMvc.perform(get("/admin/content").with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Content revisions")))
                .andExpect(content().string(containsString(revision.getContentCode().value())));

        mockMvc.perform(get("/admin/content/revisions/{id}/edit", revision.getId())
                        .with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Edit content")))
                .andExpect(content().string(containsString("Vocabulary title")))
                .andExpect(content().string(containsString("negotiate")))
                .andExpect(content().string(containsString("name=\"_csrf\"")));

        mockMvc.perform(post("/admin/content/revisions/{id}", revision.getId())
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf())
                        .params(vocabularyForm(initialVersion, "MVC updated title")))
                .andExpect(status().isFound())
                .andExpect(header().string(HttpHeaders.LOCATION,
                        "/admin/content/revisions/" + revision.getId() + "/edit"));

        var updated = repository.findById(revision.getId()).orElseThrow();
        assertThat(updated.getTitle()).isEqualTo("MVC updated title");
        assertThat(((VocabularyContentRevisionEntity) updated).getDefinition())
                .isEqualTo("updated definition");
        assertThat(updated.getChecksum().value()).isNotEqualTo("a".repeat(64));
    }

    @Test
    void stateChangingContentRequestRequiresCsrf() throws Exception {
        var revision = repository.saveAndFlush(vocabulary());

        mockMvc.perform(post("/admin/content/revisions/{id}", revision.getId())
                        .with(user("admin").roles("ADMIN"))
                        .params(vocabularyForm(revision.getVersion(), "Blocked")))
                .andExpect(status().isForbidden());
    }

    @Test
    void forgedContentTypeIsRejectedWithoutMutation() throws Exception {
        var revision = repository.saveAndFlush(vocabulary());
        var params = vocabularyForm(revision.getVersion(), "Should not persist");
        params.set("bodyType", "question");

        mockMvc.perform(post("/admin/content/revisions/{id}", revision.getId())
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf())
                        .params(params))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Content type cannot be changed")));

        assertThat(repository.findById(revision.getId()).orElseThrow().getTitle())
                .isEqualTo("Vocabulary title");
    }

    @Test
    void staleVersionUsesSafeConflictPage() throws Exception {
        var revision = repository.saveAndFlush(vocabulary());
        var staleVersion = revision.getVersion();

        authoring.updateDraft(
                revision.getId(),
                staleVersion,
                new ContentDraftUpdate(
                        new Sha256Digest("b".repeat(64)),
                        "Concurrent title",
                        "Vocabulary subtitle",
                        "Vocabulary description",
                        new CatalogueCode("VOCABULARY"),
                        new CatalogueCode("B2"),
                        4,
                        List.of(new CatalogueCode("SPEAKING")),
                        AvailabilityStatus.ACTIVE,
                        new ContentDraftUpdate.VocabularyBody(
                                "negotiate",
                                "concurrent definition",
                                "verb",
                                List.of("Concurrent example"))));

        mockMvc.perform(post("/admin/content/revisions/{id}", revision.getId())
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf())
                        .params(vocabularyForm(staleVersion, "Stale title")))
                .andExpect(status().isConflict())
                .andExpect(content().string(containsString("Update conflict")))
                .andExpect(content().string(containsString("Reload and try again")))
                .andExpect(content().string(org.hamcrest.Matchers.not(containsString("Stale content revision version"))));
    }

    private static org.springframework.util.LinkedMultiValueMap<String, String> vocabularyForm(long version, String title) {
        var params = new org.springframework.util.LinkedMultiValueMap<String, String>();
        params.add("expectedVersion", Long.toString(version));
        params.add("title", title);
        params.add("subtitle", "Vocabulary subtitle");
        params.add("description", "Vocabulary description");
        params.add("categoryCode", "VOCABULARY");
        params.add("levelCode", "B2");
        params.add("minutes", "4");
        params.add("skillCodes", "SPEAKING\nLISTENING");
        params.add("availability", "ACTIVE");
        params.add("bodyType", "vocabulary");
        params.add("term", "negotiate");
        params.add("definition", "updated definition");
        params.add("partOfSpeech", "verb");
        params.add("examples", "Example one\nExample two");
        return params;
    }

    private static VocabularyContentRevisionEntity vocabulary() {
        return new VocabularyContentRevisionEntity(
                new BusinessCode("mvc-vocabulary-" + UUID.randomUUID()),
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
                List.of("Example one"));
    }
}
