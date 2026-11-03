package io.github.alimbetov.voxprep.backend.catalogue.web;

import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
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
import tools.jackson.databind.ObjectMapper;

@ActiveProfiles("test")
@SpringBootTest
class AdminCatalogueAuthoringIntegrationTest {

    @Autowired private WebApplicationContext context;
    @Autowired private ObjectMapper objectMapper;
    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
    }

    @Test
    void adminCanAuthorHierarchyAndStaleUpdateFailsClosed() throws Exception {
        var verticalResult = mockMvc.perform(post("/admin/api/v1/catalogue/verticals")
                        .header(HttpHeaders.AUTHORIZATION, basicAuth())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"BACKEND","sectionCode":"CAREER","title":"Backend","description":"Backend engineering","iconAssetId":"backend.svg","sortOrder":0,"availability":"ACTIVE"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.version").value(0))
                .andReturn();
        UUID verticalId = UUID.fromString(objectMapper.readTree(verticalResult.getResponse().getContentAsString()).get("id").asText());

        var goalResult = mockMvc.perform(post("/admin/api/v1/catalogue/goals")
                        .header(HttpHeaders.AUTHORIZATION, basicAuth())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"JAVA","verticalId":"%s","title":"Java","description":"Java backend","sortOrder":0,"availability":"ACTIVE"}
                                """.formatted(verticalId)))
                .andExpect(status().isOk())
                .andReturn();
        UUID goalId = UUID.fromString(objectMapper.readTree(goalResult.getResponse().getContentAsString()).get("id").asText());

        var trackResult = mockMvc.perform(post("/admin/api/v1/catalogue/tracks")
                        .header(HttpHeaders.AUTHORIZATION, basicAuth())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"JAVA_SENIOR","goalId":"%s","title":"Senior Java","description":"Senior track","levelCode":"SENIOR","careerTrackCode":"BACKEND","sortOrder":0,"availability":"ACTIVE"}
                                """.formatted(goalId)))
                .andExpect(status().isOk())
                .andReturn();
        UUID trackId = UUID.fromString(objectMapper.readTree(trackResult.getResponse().getContentAsString()).get("id").asText());

        mockMvc.perform(post("/admin/api/v1/catalogue/collections")
                        .header(HttpHeaders.AUTHORIZATION, basicAuth())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"JAVA_CORE","trackId":"%s","title":"Java Core","description":"Core knowledge","accessLevel":"FREE","sortOrder":0,"availability":"ACTIVE"}
                                """.formatted(trackId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessLevel").value("FREE"));

        String update = """
                {"expectedVersion":0,"code":"BACKEND","sectionCode":"CAREER","title":"Backend Updated","description":"Backend engineering","iconAssetId":"backend.svg","sortOrder":0,"availability":"ACTIVE"}
                """;
        mockMvc.perform(put("/admin/api/v1/catalogue/verticals/{id}", verticalId)
                        .header(HttpHeaders.AUTHORIZATION, basicAuth())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(update))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title").value("Backend Updated"));

        mockMvc.perform(put("/admin/api/v1/catalogue/verticals/{id}", verticalId)
                        .header(HttpHeaders.AUTHORIZATION, basicAuth())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(update))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("CATALOGUE_CONFLICT"));
    }

    private static String basicAuth() {
        return "Basic " + Base64.getEncoder().encodeToString("admin:777".getBytes(StandardCharsets.UTF_8));
    }
}
