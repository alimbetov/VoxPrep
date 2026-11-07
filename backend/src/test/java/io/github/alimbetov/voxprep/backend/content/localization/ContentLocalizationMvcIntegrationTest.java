package io.github.alimbetov.voxprep.backend.content.localization;

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
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

@ActiveProfiles("test")
@SpringBootTest
class ContentLocalizationMvcIntegrationTest {

    @Autowired private WebApplicationContext context;
    @Autowired private ContentRevisionRepository contents;
    @Autowired private ContentLocalizationAuthoringService localizations;
    @Autowired private JdbcTemplate jdbc;
    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
    }

    @Test
    void adminCanCreateBrowseAndEditLocalizationDraft() throws Exception {
        var revision = contents.saveAndFlush(vocabulary());
        var contentId = revision.getId();

        mvc.perform(get("/admin/content/revisions/{id}/localizations", contentId)
                        .with(user("editor").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Переводы материала")));

        mvc.perform(get("/admin/content/revisions/{id}/localizations/new", contentId)
                        .with(user("editor").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Код языка (BCP-47)")))
                .andExpect(content().string(containsString("name=\"_csrf\"")));

        mvc.perform(post("/admin/content/revisions/{id}/localizations", contentId)
                        .with(user("editor").roles("ADMIN"))
                        .with(csrf())
                        .param("expectedVersion", "0")
                        .param("locale", "kk-KZ")
                        .param("title", "Бірінші атау")
                        .param("translation", "Келіссөз жүргізу"))
                .andExpect(status().isFound())
                .andExpect(header().string(HttpHeaders.LOCATION,
                        org.hamcrest.Matchers.containsString("/admin/content/localizations/")));

        var created = localizations.listByContent(contentId);
        assertThat(created).hasSize(1);
        var initial = created.getFirst();
        assertThat(initial.locale()).isEqualTo("kk-KZ");
        assertThat(initial.lifecycle()).isEqualTo(ContentLocalizationLifecycleStatus.DRAFT);

        mvc.perform(get("/admin/content/localizations/{id}/edit", initial.id())
                        .with(user("editor").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Келіссөз жүргізу")));

        mvc.perform(post("/admin/content/localizations/{id}", initial.id())
                        .with(user("editor").roles("ADMIN"))
                        .with(csrf())
                        .param("expectedVersion", Long.toString(initial.version()))
                        .param("locale", "kk-KZ")
                        .param("title", "Жаңа атау")
                        .param("translation", "Жаңа аударма"))
                .andExpect(status().isFound());

        var updated = localizations.get(initial.id());
        assertThat(updated.title()).isEqualTo("Жаңа атау");
        assertThat(updated.checksumSha256()).isNotEqualTo(initial.checksumSha256());

        mvc.perform(get("/admin/content/revisions/{id}/localizations", contentId)
                        .with(user("editor").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Жаңа атау")));
    }

    @Test
    void mutationsRequireCsrfAndStaleVersionReturnsSafeConflict() throws Exception {
        var revision = contents.saveAndFlush(vocabulary());
        var contentId = revision.getId();
        mvc.perform(post("/admin/content/revisions/{id}/localizations", contentId)
                        .with(user("editor").roles("ADMIN"))
                        .param("expectedVersion", "0")
                        .param("locale", "fr")
                        .param("title", "Refusé"))
                .andExpect(status().isForbidden());

        var first = localizations.create(contentId, "fr",
                new Sha256Digest("a".repeat(64)),
                new ContentLocalizationAuthoringService.Fields("Premier", null, null, null, null, null));
        localizations.updateDraft(first.id(), first.version(),
                new Sha256Digest("b".repeat(64)),
                new ContentLocalizationAuthoringService.Fields("Courant", null, null, null, null, null));

        mvc.perform(post("/admin/content/localizations/{id}", first.id())
                        .with(user("editor").roles("ADMIN"))
                        .with(csrf())
                        .param("expectedVersion", Long.toString(first.version()))
                        .param("locale", "fr")
                        .param("title", "Périmé"))
                .andExpect(status().isConflict())
                .andExpect(content().string(containsString("Update conflict")));

        assertThat(localizations.get(first.id()).title()).isEqualTo("Courant");
    }

    @Test
    void localizationLifecycleWritesAuthenticatedAuditAndNextDraft() throws Exception {
        var revision = contents.saveAndFlush(vocabulary());
        var initial = localizations.create(revision.getId(), "kk-KZ",
                new Sha256Digest("a".repeat(64)),
                new ContentLocalizationAuthoringService.Fields(
                        "Алғашқы нұсқа", null, null, "Аударма", null, null));
        var id = initial.id();

        mvc.perform(get("/admin/content/localizations/{id}/edit", id)
                        .with(user("reviewer").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Передать перевод на проверку")));

        mvc.perform(post("/admin/content/localizations/{id}/review", id)
                        .with(user("reviewer").roles("ADMIN")).with(csrf())
                        .param("expectedVersion", Long.toString(initial.version()))
                        .param("reason", "translation checked")
                        .param("comment", "ready for approval"))
                .andExpect(status().isFound());
        var pending = localizations.get(id);
        assertThat(pending.lifecycle()).isEqualTo(ContentLocalizationLifecycleStatus.READY_FOR_REVIEW);

        mvc.perform(get("/admin/content/localizations/{id}/edit", id)
                        .with(user("approver").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Одобрить перевод")));

        mvc.perform(post("/admin/content/localizations/{id}/approve", id)
                        .with(user("approver").roles("ADMIN")).with(csrf())
                        .param("expectedVersion", Long.toString(pending.version()))
                        .param("reason", "approved translation")
                        .param("comment", "release-ready"))
                .andExpect(status().isFound());

        var approved = localizations.get(id);
        assertThat(approved.lifecycle()).isEqualTo(ContentLocalizationLifecycleStatus.APPROVED);
        assertThat(approved.approvedAt()).isNotNull();

        var audit = jdbc.queryForList(
                "select action, actor, reason from app.content_localization_review_audit "
                        + "where localization_revision_id = ? order by occurred_at, action",
                id);
        assertThat(audit).hasSize(2);
        assertThat(audit).anySatisfy(row -> {
            assertThat(row.get("action")).isEqualTo("SUBMITTED_FOR_REVIEW");
            assertThat(row.get("actor")).isEqualTo("reviewer");
            assertThat(row.get("reason")).isEqualTo("translation checked");
        });
        assertThat(audit).anySatisfy(row -> {
            assertThat(row.get("action")).isEqualTo("APPROVED");
            assertThat(row.get("actor")).isEqualTo("approver");
        });

        mvc.perform(post("/admin/content/localizations/{id}/next", id)
                        .with(user("editor").roles("ADMIN")).with(csrf())
                        .param("expectedVersion", Long.toString(approved.version())))
                .andExpect(status().isFound())
                .andExpect(header().string(HttpHeaders.LOCATION,
                        containsString("/admin/content/localizations/")));

        var versions = localizations.listByContent(revision.getId());
        assertThat(versions).hasSize(2);
        assertThat(versions).anySatisfy(value -> {
            if (value.localizationRevisionNumber() == 2) {
                assertThat(value.lifecycle()).isEqualTo(ContentLocalizationLifecycleStatus.DRAFT);
                assertThat(value.locale()).isEqualTo("kk-KZ");
            }
        });
    }

    @Test
    void invalidLifecycleAndForgedLocaleFailClosed() throws Exception {
        var revision = contents.saveAndFlush(vocabulary());
        var initial = localizations.create(revision.getId(), "fr",
                new Sha256Digest("a".repeat(64)),
                new ContentLocalizationAuthoringService.Fields("Titre", null, null, null, null, null));

        mvc.perform(post("/admin/content/localizations/{id}/approve", initial.id())
                        .with(user("approver").roles("ADMIN")).with(csrf())
                        .param("expectedVersion", Long.toString(initial.version())))
                .andExpect(status().isConflict());
        assertThat(localizations.get(initial.id()).lifecycle())
                .isEqualTo(ContentLocalizationLifecycleStatus.DRAFT);

        mvc.perform(post("/admin/content/localizations/{id}/review", initial.id())
                        .with(user("reviewer").roles("ADMIN"))
                        .param("expectedVersion", Long.toString(initial.version())))
                .andExpect(status().isForbidden());

        mvc.perform(post("/admin/content/localizations/{id}", initial.id())
                        .with(user("editor").roles("ADMIN")).with(csrf())
                        .param("expectedVersion", Long.toString(initial.version()))
                        .param("locale", "en-US")
                        .param("title", "Forged"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Localization locale cannot be changed")));
        assertThat(localizations.get(initial.id()).title()).isEqualTo("Titre");

        mvc.perform(post("/admin/content/localizations/{id}/review", initial.id())
                        .with(user("reviewer").roles("ADMIN")).with(csrf())
                        .param("expectedVersion", Long.toString(initial.version() + 1)))
                .andExpect(status().isConflict());

        var auditRows = jdbc.queryForObject(
                "select count(*) from app.content_localization_review_audit "
                        + "where localization_revision_id = ?",
                Integer.class, initial.id());
        assertThat(auditRows).isZero();
    }

    private static VocabularyContentRevisionEntity vocabulary() {
        return new VocabularyContentRevisionEntity(
                new BusinessCode("mvc-localization-" + UUID.randomUUID()),
                new RevisionNumber(1),
                new Sha256Digest("a".repeat(64)),
                "Vocabulary title", "Vocabulary subtitle", "Vocabulary description",
                new CatalogueCode("VOCABULARY"), new CatalogueCode("B2"),
                4, List.of(new CatalogueCode("SPEAKING")),
                AvailabilityStatus.ACTIVE,
                "negotiate", "to discuss", "verb", List.of("Example one"));
    }
}
