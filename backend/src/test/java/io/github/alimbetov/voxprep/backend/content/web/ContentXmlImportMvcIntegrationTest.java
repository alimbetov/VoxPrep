package io.github.alimbetov.voxprep.backend.content.web;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.core.io.ClassPathResource;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

@ActiveProfiles("test")
@SpringBootTest
class ContentXmlImportMvcIntegrationTest {
    @Autowired private WebApplicationContext context;
    @Autowired private ContentRevisionRepository repository;
    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
    }

    @Test
    void adminCanDownloadTemplateAndSchemaButLearnerCannot() throws Exception {
        mvc.perform(get("/admin/imports/template.xml").with(user("editor").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("voxprep schemaVersion=\"1\"")));
        mvc.perform(get("/admin/imports/schema.xsd").with(user("editor").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("xs:schema")));
        mvc.perform(get("/admin/imports/template.xml").with(user("learner").roles("USER")))
                .andExpect(status().isForbidden());
    }

    @Test
    void importRequiresSameValidatedFileAndFreshSession() throws Exception {
        byte[] xml = new String(new ClassPathResource("imports/voxprep-content-template-v1.xml")
                .getContentAsByteArray(), java.nio.charset.StandardCharsets.UTF_8)
                .replaceAll("(?s)\\s*<content code=\"PRACTICE_ARCH_01\".*?</content>", "")
                .getBytes(java.nio.charset.StandardCharsets.UTF_8);
        var session = new MockHttpSession();
        var upload = new MockMultipartFile("file", "example.xml", "application/xml", xml);
        long before = repository.count();

        mvc.perform(multipart("/admin/imports/import-drafts").file(upload)
                        .session(session).with(user("editor").roles("ADMIN")).with(csrf()))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Validation expired")));

        mvc.perform(multipart("/admin/imports/validate").file(upload)
                        .session(session).with(user("editor").roles("ADMIN")).with(csrf()))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Import as DRAFT")));

        var changed = new MockMultipartFile("file", "changed.xml", "application/xml",
                new String(xml, java.nio.charset.StandardCharsets.UTF_8)
                        .replace("Resilience", "Changed").getBytes(java.nio.charset.StandardCharsets.UTF_8));
        mvc.perform(multipart("/admin/imports/import-drafts").file(changed)
                        .session(session).with(user("editor").roles("ADMIN")).with(csrf()))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("XML changed since validation")));

        mvc.perform(multipart("/admin/imports/import-drafts").file(upload)
                        .session(session).with(user("editor").roles("ADMIN")))
                .andExpect(status().isForbidden());
        assertThat(repository.count()).isEqualTo(before);
    }

    @Test
    void fullAuthenticatedFlowCreatesOneDraftThenReplaysWithoutDuplicates() throws Exception {
        String template = new String(new ClassPathResource("imports/voxprep-content-template-v1.xml")
                .getContentAsByteArray(), java.nio.charset.StandardCharsets.UTF_8);
        int start = template.indexOf("  <content code=\"PHRASE_INTERVIEW_INTRO_01\"");
        int end = template.indexOf("</content>", start) + "</content>".length();
        String code = "HTTP_XML_" + java.util.UUID.randomUUID().toString().replace("-", "");
        String xml = "<voxprep schemaVersion=\"1\">"
                + template.substring(start, end).replace("PHRASE_INTERVIEW_INTRO_01", code)
                + "</voxprep>";
        var payload = new MockMultipartFile("file", "draft.xml", "application/xml",
                xml.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        var session = new MockHttpSession();
        long before = repository.count();

        mvc.perform(multipart("/admin/imports/validate").file(payload)
                        .session(session).with(user("editor").roles("ADMIN")).with(csrf()))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Database preflight")))
                .andExpect(content().string(containsString("Import as DRAFT")));
        assertThat(repository.count()).isEqualTo(before);

        mvc.perform(multipart("/admin/imports/import-drafts").file(payload)
                        .session(session).with(user("editor").roles("ADMIN")).with(csrf()))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Import committed")));
        assertThat(repository.count()).isEqualTo(before + 1);
        assertThat(repository.findIdByExactIdentity(code, "phrase", 1)).isPresent();

        mvc.perform(multipart("/admin/imports/import-drafts").file(payload)
                        .session(session).with(user("editor").roles("ADMIN")).with(csrf()))
                .andExpect(content().string(containsString("Validation expired")));
        mvc.perform(multipart("/admin/imports/validate").file(payload)
                        .session(session).with(user("editor").roles("ADMIN")).with(csrf()))
                .andExpect(content().string(containsString("Import as DRAFT")));
        mvc.perform(multipart("/admin/imports/import-drafts").file(payload)
                        .session(session).with(user("editor").roles("ADMIN")).with(csrf()))
                .andExpect(content().string(containsString("Import committed")));
        assertThat(repository.count()).isEqualTo(before + 1);
    }

    @Test
    void learnerCannotValidateOrImportAndOversizedFileNeverOpensConfirmation() throws Exception {
        byte[] valid = new ClassPathResource("imports/voxprep-content-template-v1.xml")
                .getContentAsByteArray();
        var payload = new MockMultipartFile("file", "content.xml", "application/xml", valid);
        long before = repository.count();
        mvc.perform(multipart("/admin/imports/validate").file(payload)
                        .with(user("learner").roles("USER")).with(csrf()))
                .andExpect(status().isForbidden());
        mvc.perform(multipart("/admin/imports/import-drafts").file(payload)
                        .with(user("learner").roles("USER")).with(csrf()))
                .andExpect(status().isForbidden());

        var oversized = new MockMultipartFile("file", "large.xml", "application/xml",
                new byte[io.github.alimbetov.voxprep.backend.content.application
                        .ContentXmlDryRunService.MAX_BYTES + 1]);
        var session = new MockHttpSession();
        mvc.perform(multipart("/admin/imports/validate").file(oversized)
                        .session(session).with(user("editor").roles("ADMIN")).with(csrf()))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Select an XML file")))
                .andExpect(content().string(org.hamcrest.Matchers.not(containsString("Import as DRAFT"))));
        mvc.perform(multipart("/admin/imports/import-drafts").file(payload)
                        .session(session).with(user("editor").roles("ADMIN")).with(csrf()))
                .andExpect(content().string(containsString("Validation expired")));
        assertThat(repository.count()).isEqualTo(before);
    }

    @Test
    void validationOnlyCannotCreateDraftsAndRequiresCsrf() throws Exception {
        byte[] xml = new ClassPathResource("imports/voxprep-content-template-v1.xml")
                .getContentAsByteArray();
        var upload = new MockMultipartFile("file", "example.xml", "application/xml", xml);
        long before = repository.count();
        mvc.perform(multipart("/admin/imports/validate").file(upload)
                        .with(user("editor").roles("ADMIN")))
                .andExpect(status().isForbidden());

        mvc.perform(multipart("/admin/imports/validate").file(upload)
                        .with(user("editor").roles("ADMIN")).with(csrf()))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("No import was performed")));
        assertThat(repository.count()).isEqualTo(before);
    }
}
