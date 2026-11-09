package io.github.alimbetov.voxprep.backend.asset.web;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import io.github.alimbetov.voxprep.backend.asset.application.ExternalLearningVideoService;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.PhraseContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.QuestionContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.content.persistence.QuestionOptionEmbeddable;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

@ActiveProfiles("test")
@SpringBootTest
class ExternalVideoMvcIntegrationTest {
    @Autowired private WebApplicationContext context;
    @Autowired private ContentRevisionRepository revisions;
    @Autowired private ExternalLearningVideoService videos;
    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
    }

    @Test
    void adminCanSaveAndPreviewWithoutReplacingImageOrAudioSections() throws Exception {
        var draft = revisions.saveAndFlush(newDraft());
        var url = "/admin/content/revisions/" + draft.getId() + "/external-video";
        mvc.perform(post(url).with(user("admin").roles("ADMIN")).with(csrf())
                        .param("url", "https://youtu.be/AbCdEfGh123")
                        .param("title", "English job interview"))
                .andExpect(status().isFound())
                .andExpect(header().string("Location", url.replace("/external-video", "/edit")));

        assertThat(videos.find(draft.getId())).get()
                .extracting(ExternalLearningVideoService.Video::providerVideoId)
                .isEqualTo("AbCdEfGh123");
        mvc.perform(get("/admin/content/revisions/{id}/edit", draft.getId())
                        .with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("English job interview")))
                .andExpect(content().string(containsString("3. Изображения")))
                .andExpect(content().string(containsString("4. Озвучивание и проверка MP3")))
                .andExpect(content().string(containsString("Сохранить видео")));
    }

    @Test
    void csrfAndAdminAuthorizationAreRequiredForAddingOrRemovingLinks() throws Exception {
        var draft = revisions.saveAndFlush(newDraft());
        var url = "/admin/content/revisions/" + draft.getId() + "/external-video";
        mvc.perform(post(url).with(user("admin").roles("ADMIN"))
                        .param("url", "https://youtu.be/AbCdEfGh123")
                        .param("title", "Video"))
                .andExpect(status().isForbidden());
        mvc.perform(post(url).with(user("learner").roles("USER")).with(csrf())
                        .param("url", "https://youtu.be/AbCdEfGh123")
                        .param("title", "Video"))
                .andExpect(status().isForbidden());
        mvc.perform(post(url + "/remove").with(user("admin").roles("ADMIN")))
                .andExpect(status().isForbidden());
        assertThat(videos.find(draft.getId())).isEmpty();
    }

    @Test
    void badProviderDoesNotCreateLinkAndKeepsDraftEditable() throws Exception {
        var draft = revisions.saveAndFlush(newDraft());
        mvc.perform(post("/admin/content/revisions/{id}/external-video", draft.getId())
                        .with(user("admin").roles("ADMIN")).with(csrf())
                        .param("url", "https://youtube.com.evil.example/watch?v=AbCdEfGh123")
                        .param("title", "Malicious"))
                .andExpect(status().isFound());
        assertThat(videos.find(draft.getId())).isEmpty();
        mvc.perform(get("/admin/content/revisions/{id}/edit", draft.getId())
                        .with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("3. Изображения")));
    }

    @Test
    void publishedRevisionReturnsConflictForSaveAndRemove() throws Exception {
        var revision = revisions.saveAndFlush(newDraft());
        videos.save(revision.getId(), "https://youtu.be/AbCdEfGh123", "First video");
        revision.markReadyForAudio();
        revisions.saveAndFlush(revision);
        revision.markReadyForReview();
        revisions.saveAndFlush(revision);
        revision.approve(Instant.parse("2026-11-09T01:00:00Z"));
        revisions.saveAndFlush(revision);
        revision.publish(Instant.parse("2026-11-09T01:01:00Z"));
        revisions.saveAndFlush(revision);

        String url = "/admin/content/revisions/" + revision.getId() + "/external-video";
        mvc.perform(post(url).with(user("admin").roles("ADMIN")).with(csrf())
                        .param("url", "https://youtu.be/QrStUvWx123")
                        .param("title", "Overwritten"))
                .andExpect(status().isConflict())
                .andExpect(content().string(containsString("Update conflict")));
        mvc.perform(post(url + "/remove").with(user("admin").roles("ADMIN")).with(csrf()))
                .andExpect(status().isConflict());

        assertThat(videos.findPublished(revision.getId()).orElseThrow().title())
                .isEqualTo("First video");
    }

    @Test
    void assessmentQuestionCannotStoreInvisibleVideoAndHasNoVideoEditor() throws Exception {
        var question = revisions.saveAndFlush(new QuestionContentRevisionEntity(
                new BusinessCode("EV_QUESTION_" + UUID.randomUUID().toString().replace("-", "")),
                new RevisionNumber(1), new Sha256Digest("b".repeat(64)),
                "Question", "Subtitle", "Description",
                new CatalogueCode("INTERVIEW"), new CatalogueCode("B2"),
                2, List.of(new CatalogueCode("SPEAKING")), AvailabilityStatus.ACTIVE,
                "Which answer is correct?", "Explanation",
                List.of(new QuestionOptionEmbeddable("A", "Yes", true),
                        new QuestionOptionEmbeddable("B", "No", false))));
        mvc.perform(get("/admin/content/revisions/{id}/edit", question.getId())
                        .with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(content().string(not(containsString("data-external-video-section"))));

        mvc.perform(post("/admin/content/revisions/{id}/external-video", question.getId())
                        .with(user("admin").roles("ADMIN")).with(csrf())
                        .param("url", "https://youtu.be/AbCdEfGh123")
                        .param("title", "Invisible video"))
                .andExpect(status().isFound());
        assertThat(videos.find(question.getId())).isEmpty();
    }

    private static PhraseContentRevisionEntity newDraft() {
        return new PhraseContentRevisionEntity(
                new BusinessCode("EV_MVC_" + UUID.randomUUID().toString().replace("-", "")),
                new RevisionNumber(1), new Sha256Digest("a".repeat(64)),
                "Title", "Subtitle", "Description",
                new CatalogueCode("COMMUNICATION"), new CatalogueCode("B1"),
                2, List.of(new CatalogueCode("SPEAKING")), AvailabilityStatus.ACTIVE,
                "Could you clarify?", "Usage", List.of("Could you clarify the scope?"));
    }
}
