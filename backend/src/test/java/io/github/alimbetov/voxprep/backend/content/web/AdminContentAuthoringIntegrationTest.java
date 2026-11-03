package io.github.alimbetov.voxprep.backend.content.web;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.VocabularyContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.review.ContentReviewAction;
import io.github.alimbetov.voxprep.backend.content.review.ContentReviewAuditRepository;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

@ActiveProfiles("test")
@SpringBootTest
class AdminContentAuthoringIntegrationTest {

    @Autowired private WebApplicationContext context;
    @Autowired private ContentRevisionRepository repository;
    @Autowired private ContentReviewAuditRepository reviewAuditRepository;
    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .apply(springSecurity())
                .build();
    }

    @Test
    void adminApiIsSecuredVersionAwareAndWritesAuthenticatedReviewActor() throws Exception {
        var revision = repository.saveAndFlush(vocabulary());
        var id = revision.getId();
        var initialVersion = revision.getVersion();

        mockMvc.perform(get("/admin/api/v1/content/revisions/{id}", id))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(get("/admin/api/v1/content/revisions/{id}", id)
                        .header(HttpHeaders.AUTHORIZATION, basicAuth()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.contentType").value("VOCABULARY"))
                .andExpect(jsonPath("$.lifecycle").value("DRAFT"));

        mockMvc.perform(put("/admin/api/v1/content/revisions/{id}/draft", id)
                        .header(HttpHeaders.AUTHORIZATION, basicAuth())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(draftJson(initialVersion, "Updated vocabulary")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title").value("Updated vocabulary"));

        mockMvc.perform(put("/admin/api/v1/content/revisions/{id}/draft", id)
                        .header(HttpHeaders.AUTHORIZATION, basicAuth())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(draftJson(initialVersion, "Stale update")))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("CONTENT_REVISION_CONFLICT"));

        var afterDraft = repository.findById(id).orElseThrow();
        mockMvc.perform(post("/admin/api/v1/content/revisions/{id}/ready-for-audio", id)
                        .header(HttpHeaders.AUTHORIZATION, basicAuth())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"expectedVersion\":" + afterDraft.getVersion() + "}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.lifecycle").value("READY_FOR_AUDIO"));

        var afterAudio = repository.findById(id).orElseThrow();
        mockMvc.perform(post("/admin/api/v1/content/revisions/{id}/review", id)
                        .header(HttpHeaders.AUTHORIZATION, basicAuth())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"expectedVersion":%d,"reason":"editorial","comment":"ready"}
                                """.formatted(afterAudio.getVersion())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.lifecycle").value("READY_FOR_REVIEW"));

        var audits = reviewAuditRepository.findAllByContentRevisionIdOrderByOccurredAtAscIdAsc(id);
        assertThat(audits).hasSize(1);
        assertThat(audits.getFirst().getAction()).isEqualTo(ContentReviewAction.SUBMITTED_FOR_REVIEW);
        assertThat(audits.getFirst().getActor()).isEqualTo("admin");
        assertThat(audits.getFirst().getReason()).isEqualTo("editorial");
        assertThat(audits.getFirst().getComment()).isEqualTo("ready");

        var afterReview = repository.findById(id).orElseThrow();
        mockMvc.perform(post("/admin/api/v1/content/revisions/{id}/approve", id)
                        .header(HttpHeaders.AUTHORIZATION, basicAuth())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"expectedVersion":%d,"reason":"quality-gate","comment":"approved"}
                                """.formatted(afterReview.getVersion())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.lifecycle").value("APPROVED"));

        audits = reviewAuditRepository.findAllByContentRevisionIdOrderByOccurredAtAscIdAsc(id);
        assertThat(audits).hasSize(2);
        assertThat(audits.get(1).getAction()).isEqualTo(ContentReviewAction.APPROVED);
        assertThat(audits.get(1).getActor()).isEqualTo("admin");
    }

    private static VocabularyContentRevisionEntity vocabulary() {
        return new VocabularyContentRevisionEntity(
                new BusinessCode("admin-vocabulary-" + UUID.randomUUID()),
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

    private static String draftJson(long expectedVersion, String title) {
        return """
                {
                  "expectedVersion": %d,
                  "checksumSha256": "%s",
                  "title": "%s",
                  "subtitle": "Vocabulary subtitle",
                  "description": "Vocabulary description",
                  "categoryCode": "VOCABULARY",
                  "levelCode": "B2",
                  "minutes": 4,
                  "skillCodes": ["SPEAKING"],
                  "availability": "ACTIVE",
                  "body": {
                    "type": "vocabulary",
                    "term": "negotiate",
                    "definition": "to discuss in order to reach agreement",
                    "partOfSpeech": "verb",
                    "examples": ["Example one"]
                  }
                }
                """.formatted(expectedVersion, "b".repeat(64), title);
    }

    private static String basicAuth() {
        var value = Base64.getEncoder().encodeToString("admin:777".getBytes(StandardCharsets.UTF_8));
        return "Basic " + value;
    }
}
