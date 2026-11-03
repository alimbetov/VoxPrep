package io.github.alimbetov.voxprep.backend.content.web;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.domain.ContentLifecycleStatus;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.VocabularyContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.review.ContentReviewAction;
import io.github.alimbetov.voxprep.backend.content.review.ContentReviewAuditRepository;
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
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.web.context.WebApplicationContext;

@ActiveProfiles("test")
@SpringBootTest
class ContentLifecycleMvcIntegrationTest {

    @Autowired private WebApplicationContext context;
    @Autowired private ContentRevisionRepository revisions;
    @Autowired private ContentReviewAuditRepository audits;
    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .apply(springSecurity())
                .build();
    }

    @Test
    void lifecycleUsesDomainTransitionsAuthenticatedActorsAndCreatesNextDraft() throws Exception {
        var revision = revisions.saveAndFlush(vocabulary());

        performLifecycle(revision.getId(), "ready-for-audio", revision.getVersion(), "editor", null, null);
        var readyForAudio = revisions.findById(revision.getId()).orElseThrow();
        assertThat(readyForAudio.getLifecycle()).isEqualTo(ContentLifecycleStatus.READY_FOR_AUDIO);

        performLifecycle(revision.getId(), "review", readyForAudio.getVersion(), "reviewer-user", "ready", "review me");
        var readyForReview = revisions.findById(revision.getId()).orElseThrow();
        assertThat(readyForReview.getLifecycle()).isEqualTo(ContentLifecycleStatus.READY_FOR_REVIEW);

        performLifecycle(revision.getId(), "approve", readyForReview.getVersion(), "approver-user", "accepted", "looks good");
        var approved = revisions.findById(revision.getId()).orElseThrow();
        assertThat(approved.getLifecycle()).isEqualTo(ContentLifecycleStatus.APPROVED);

        var audit = audits.findAllByContentRevisionIdOrderByOccurredAtAscIdAsc(revision.getId());
        assertThat(audit).hasSize(2);
        assertThat(audit.get(0).getAction()).isEqualTo(ContentReviewAction.SUBMITTED_FOR_REVIEW);
        assertThat(audit.get(0).getActor()).isEqualTo("reviewer-user");
        assertThat(audit.get(0).getReason()).isEqualTo("ready");
        assertThat(audit.get(1).getAction()).isEqualTo(ContentReviewAction.APPROVED);
        assertThat(audit.get(1).getActor()).isEqualTo("approver-user");
        assertThat(audit.get(1).getReason()).isEqualTo("accepted");

        var result = mockMvc.perform(post("/admin/content/revisions/{id}/next", revision.getId())
                        .with(user("editor").roles("ADMIN"))
                        .with(csrf())
                        .params(lifecycle(approved.getVersion(), null, null)))
                .andExpect(status().isFound())
                .andReturn();

        var location = result.getResponse().getHeader(HttpHeaders.LOCATION);
        assertThat(location).startsWith("/admin/content/revisions/").endsWith("/edit");
        var createdId = UUID.fromString(location.substring(
                "/admin/content/revisions/".length(), location.length() - "/edit".length()));
        var created = revisions.findById(createdId).orElseThrow();
        assertThat(created.getLifecycle()).isEqualTo(ContentLifecycleStatus.DRAFT);
        assertThat(created.getRevisionNumber().value()).isEqualTo(2);
        assertThat(created.getContentCode()).isEqualTo(revision.getContentCode());
    }

    @Test
    void illegalLifecycleTransitionUsesSafeConflictBoundary() throws Exception {
        var revision = revisions.saveAndFlush(vocabulary());

        mockMvc.perform(post("/admin/content/revisions/{id}/approve", revision.getId())
                        .with(user("approver-user").roles("ADMIN"))
                        .with(csrf())
                        .params(lifecycle(revision.getVersion(), "invalid", "must not approve draft")))
                .andExpect(status().isConflict())
                .andExpect(content().string(containsString("Update conflict")))
                .andExpect(content().string(containsString("Reload and try again")));

        assertThat(revisions.findById(revision.getId()).orElseThrow().getLifecycle())
                .isEqualTo(ContentLifecycleStatus.DRAFT);
        assertThat(audits.findAllByContentRevisionIdOrderByOccurredAtAscIdAsc(revision.getId())).isEmpty();
    }

    @Test
    void lifecycleMutationRequiresCsrf() throws Exception {
        var revision = revisions.saveAndFlush(vocabulary());

        mockMvc.perform(post("/admin/content/revisions/{id}/ready-for-audio", revision.getId())
                        .with(user("editor").roles("ADMIN"))
                        .params(lifecycle(revision.getVersion(), null, null)))
                .andExpect(status().isForbidden());
    }

    private void performLifecycle(
            UUID revisionId,
            String action,
            long version,
            String username,
            String reason,
            String comment) throws Exception {
        mockMvc.perform(post("/admin/content/revisions/{id}/{action}", revisionId, action)
                        .with(user(username).roles("ADMIN"))
                        .with(csrf())
                        .params(lifecycle(version, reason, comment)))
                .andExpect(status().isFound())
                .andExpect(header().string(HttpHeaders.LOCATION,
                        "/admin/content/revisions/" + revisionId + "/edit"));
    }

    private static LinkedMultiValueMap<String, String> lifecycle(long version, String reason, String comment) {
        var params = new LinkedMultiValueMap<String, String>();
        params.add("expectedVersion", Long.toString(version));
        if (reason != null) {
            params.add("reason", reason);
        }
        if (comment != null) {
            params.add("comment", comment);
        }
        return params;
    }

    private static VocabularyContentRevisionEntity vocabulary() {
        return new VocabularyContentRevisionEntity(
                new BusinessCode("mvc-lifecycle-" + UUID.randomUUID()),
                new RevisionNumber(1),
                new Sha256Digest("c".repeat(64)),
                "Lifecycle vocabulary",
                "Lifecycle subtitle",
                "Lifecycle description",
                new CatalogueCode("VOCABULARY"),
                new CatalogueCode("B2"),
                3,
                List.of(new CatalogueCode("SPEAKING")),
                AvailabilityStatus.ACTIVE,
                "negotiate",
                "reach agreement",
                "verb",
                List.of("Example"));
    }
}
