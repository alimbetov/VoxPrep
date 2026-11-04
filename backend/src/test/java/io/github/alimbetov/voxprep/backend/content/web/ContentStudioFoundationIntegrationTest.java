package io.github.alimbetov.voxprep.backend.content.web;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.httpBasic;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import jakarta.persistence.OptimisticLockException;
import java.util.NoSuchElementException;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.web.context.WebApplicationContext;

@ActiveProfiles("test")
@SpringBootTest
class ContentStudioFoundationIntegrationTest {

    @Autowired private WebApplicationContext context;
    @Autowired private PasswordEncoder passwordEncoder;
    @Autowired private UserDetailsService userDetailsService;
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
    void realAdminLoginCreatesSessionAndRendersSharedLayout() throws Exception {
        MvcResult login = mockMvc.perform(post("/login")
                        .with(csrf())
                        .param("username", "admin")
                        .param("password", "777"))
                .andExpect(status().isFound())
                .andReturn();

        assertThat(login.getRequest().getSession(false)).isInstanceOf(MockHttpSession.class);
        var session = (MockHttpSession) login.getRequest().getSession(false);

        mockMvc.perform(get("/admin").session(session))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("VoxPrep Content Studio")))
                .andExpect(content().string(containsString("Dashboard")))
                .andExpect(content().string(containsString("Catalogue")))
                .andExpect(content().string(containsString("Content")))
                .andExpect(content().string(containsString("Localization")))
                .andExpect(content().string(containsString("Publication")))
                .andExpect(content().string(containsString("Imports")))
                .andExpect(content().string(containsString("name=\"_csrf\"")))
                .andExpect(content().string(containsString("htmx:configRequest")));

        mockMvc.perform(get("/admin/publication").session(session))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Publication readiness")));
    }

    @Test
    void invalidPasswordIsRejected() throws Exception {
        mockMvc.perform(post("/login")
                        .with(csrf())
                        .param("username", "admin")
                        .param("password", "wrong"))
                .andExpect(status().isFound())
                .andExpect(header().string(HttpHeaders.LOCATION, containsString("/login?error")));
    }

    @Test
    void configuredAdminCredentialIsEncoded() {
        var admin = userDetailsService.loadUserByUsername("admin");
        assertThat(admin.getPassword()).doesNotStartWith("{noop}");
        assertThat(passwordEncoder.matches("777", admin.getPassword())).isTrue();
    }

    @Test
    void nonAdminSessionIsForbidden() throws Exception {
        mockMvc.perform(get("/admin").with(user("learner").roles("USER")))
                .andExpect(status().isForbidden());
    }

    @Test
    void adminApiRemainsBasicAndDoesNotRedirectToMvcLogin() throws Exception {
        mockMvc.perform(get("/admin/api/v1/content/revisions/{id}", UUID.randomUUID()))
                .andExpect(status().isUnauthorized())
                .andExpect(header().doesNotExist(HttpHeaders.LOCATION))
                .andExpect(header().string(HttpHeaders.WWW_AUTHENTICATE, containsString("Basic")));
    }

    @Test
    void mvcStateChangingRequestsRequireCsrfIncludingHtmxHeaderFlow() throws Exception {
        mockMvc.perform(post("/logout").with(user("admin").roles("ADMIN")))
                .andExpect(status().isForbidden());

        mockMvc.perform(post("/logout")
                        .header("HX-Request", "true")
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf().asHeader()))
                .andExpect(status().isFound())
                .andExpect(header().string(HttpHeaders.LOCATION, containsString("/login?logout")));
    }

    @Test
    void localizationWriteEndpointsRejectAnonymousAndNonAdminCallers() throws Exception {
        UUID id = UUID.randomUUID();

        mockMvc.perform(post("/admin/api/v1/content/localizations")
                        .contentType("application/json")
                        .content("{\"contentRevisionId\":\"" + id + "\",\"locale\":\"fr\",\"title\":\"Forged\"}"))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(get("/admin/api/v1/content/localizations/{id}", id))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(post("/admin/content/localizations/{id}/approve", id)
                        .with(user("learner").roles("USER"))
                        .with(csrf())
                        .param("expectedVersion", "0"))
                .andExpect(status().isForbidden());

        mockMvc.perform(post("/admin/content/localizations/{id}/review", id)
                        .with(user("admin").roles("ADMIN"))
                        .param("expectedVersion", "0"))
                .andExpect(status().isForbidden());
    }

    @Test
    void localizationRestRejectsInvalidLocaleAndOversizedReviewReason() throws Exception {
        var id = UUID.randomUUID();
        mockMvc.perform(post("/admin/api/v1/content/localizations")
                        .with(httpBasic("admin", "777"))
                        .contentType("application/json")
                        .content("{\"contentRevisionId\":\"" + id
                                + "\",\"locale\":\"bad!locale\",\"title\":\"Title\"}"))
                .andExpect(status().isBadRequest());

        mockMvc.perform(post("/admin/api/v1/content/localizations/{id}/review", id)
                        .with(httpBasic("admin", "777"))
                        .contentType("application/json")
                        .content("{\"expectedVersion\":0,\"reason\":\""
                                + "x".repeat(513) + "\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void localWebjarAssetsResolveWithoutAdminAuthentication() throws Exception {
        mockMvc.perform(get("/webjars/bootstrap/5.3.8/css/bootstrap.min.css"))
                .andExpect(status().isOk());
        mockMvc.perform(get("/webjars/htmx.org/2.0.10/dist/htmx.min.js"))
                .andExpect(status().isOk());
    }

    @Test
    void safeMvcExceptionBoundaryUses404And409WithoutLeakingExceptionMessages() {
        var handler = new AdminContentStudioExceptionHandler();

        var notFound = handler.notFound(new NoSuchElementException("sensitive repository detail"));
        assertThat(notFound.getStatus()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(notFound.getViewName()).isEqualTo("admin/error");
        assertThat(notFound.getModel().values()).noneMatch(value -> String.valueOf(value).contains("sensitive"));

        var conflict = handler.conflict(new OptimisticLockException("database row detail"));
        assertThat(conflict.getStatus()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(conflict.getViewName()).isEqualTo("admin/error");
        assertThat(conflict.getModel().values()).noneMatch(value -> String.valueOf(value).contains("database"));
    }
}
