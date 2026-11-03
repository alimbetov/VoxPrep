package io.github.alimbetov.voxprep.backend.content.web;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

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
class ContentStudioFoundationIntegrationTest {

    @Autowired private WebApplicationContext context;
    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .apply(springSecurity())
                .build();
    }

    @Test
    void anonymousBrowserIsRedirectedToSessionLogin() throws Exception {
        mockMvc.perform(get("/admin"))
                .andExpect(status().isFound())
                .andExpect(header().string(HttpHeaders.LOCATION, containsString("/login")));
    }

    @Test
    void adminSessionRendersDashboardAndNormativeNavigation() throws Exception {
        mockMvc.perform(get("/admin").with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("VoxPrep Content Studio")))
                .andExpect(content().string(containsString("Dashboard")))
                .andExpect(content().string(containsString("Catalogue")))
                .andExpect(content().string(containsString("Content")))
                .andExpect(content().string(containsString("Localization")))
                .andExpect(content().string(containsString("Publication")))
                .andExpect(content().string(containsString("Imports")));

        mockMvc.perform(get("/admin/publication").with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Publication readiness")));
    }

    @Test
    void nonAdminSessionIsForbidden() throws Exception {
        mockMvc.perform(get("/admin").with(user("learner").roles("USER")))
                .andExpect(status().isForbidden());
    }

    @Test
    void mvcStateChangingEndpointRemainsCsrfProtected() throws Exception {
        mockMvc.perform(post("/logout").with(user("admin").roles("ADMIN")))
                .andExpect(status().isForbidden());

        mockMvc.perform(post("/logout")
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf()))
                .andExpect(status().isFound())
                .andExpect(header().string(HttpHeaders.LOCATION, containsString("/login?logout")));
    }
}
