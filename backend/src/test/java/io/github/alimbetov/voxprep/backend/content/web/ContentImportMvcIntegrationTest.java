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
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

/** Real MVC + PostgreSQL test of preview -> authorized import -> DRAFT. */
@SpringBootTest
@ActiveProfiles("test")
class ContentImportMvcIntegrationTest {
    @Autowired WebApplicationContext context;
    @Autowired ContentRevisionRepository revisions;
    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context)
                .apply(springSecurity()).build();
    }

    @Test
    void adminMustPreviewExactFileThenCreatesRealDraft() throws Exception {
        var code = "IMPORT_TEST_" + UUID.randomUUID().toString().replace("-", "");
        var bytes = """
                {"schemaVersion":1,"items":[{
                "contentCode":"%s","bodyType":"phrase",
                "title":"Hello","subtitle":"Greeting",
                "description":"Greeting exercise","categoryCode":"ENGLISH","levelCode":"B1",
                "minutes":3,"availability":"ACTIVE","skillCodes":["SPEAKING"],
                "body":{"phrase":"Hello","usage":"Say hello","examples":["Hello there"]}
                }]}
                """.formatted(code).getBytes(StandardCharsets.UTF_8);
        var session = new MockHttpSession();

        mvc.perform(get("/admin/imports/json").with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Validate and preview")));

        var file = new MockMultipartFile("file", "demo.json", "application/json", bytes);

        mvc.perform(multipart("/admin/imports/json/import").file(file)
                        .session(session).with(user("admin").roles("ADMIN")).with(csrf()))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Preview this exact file")));

        assertThat(revisions.findIdByExactIdentity(code, "phrase", 1)).isEmpty();

        mvc.perform(multipart("/admin/imports/json/preview").file(file)
                        .session(session).with(user("admin").roles("ADMIN")).with(csrf()))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Validation passed")));

        assertThat(revisions.findIdByExactIdentity(code, "phrase", 1)).isEmpty();

        mvc.perform(multipart("/admin/imports/json/import").file(file)
                        .session(session).with(user("admin").roles("ADMIN")).with(csrf()))
                .andExpect(status().is3xxRedirection());

        var id = revisions.findIdByExactIdentity(code, "phrase", 1).orElseThrow();
        assertThat(revisions.findById(id).orElseThrow().getLifecycle().name())
                .isEqualTo("DRAFT");
    }

    @Test
    void unauthorizedImportCannotWrite() throws Exception {
        var file = new MockMultipartFile("file", "demo.json",
                "application/json", "{}".getBytes(StandardCharsets.UTF_8));
        mvc.perform(multipart("/admin/imports/json/import").file(file)
                        .with(user("learner").roles("USER")).with(csrf()))
                .andExpect(status().isForbidden());
    }
}
