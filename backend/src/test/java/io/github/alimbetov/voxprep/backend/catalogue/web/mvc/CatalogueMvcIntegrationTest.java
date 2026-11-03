package io.github.alimbetov.voxprep.backend.catalogue.web.mvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import io.github.alimbetov.voxprep.backend.catalogue.application.CatalogueAdminQueryService;
import io.github.alimbetov.voxprep.backend.catalogue.application.CatalogueAuthoringService;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
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
class CatalogueMvcIntegrationTest {

    @Autowired private WebApplicationContext context;
    @Autowired private CatalogueAdminQueryService query;
    @Autowired private CatalogueAuthoringService authoring;
    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
    }

    @Test
    void adminCanCreateCompleteCatalogueHierarchyThroughMvc() throws Exception {
        String suffix = UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        String verticalCode = "V" + suffix;
        String goalCode = "G" + suffix;
        String trackCode = "T" + suffix;
        String collectionCode = "C" + suffix;

        mockMvc.perform(post("/admin/catalogue/verticals")
                        .with(user("admin").roles("ADMIN")).with(csrf())
                        .param("expectedVersion", "0")
                        .param("code", verticalCode)
                        .param("sectionCode", "CAREER")
                        .param("title", "Engineering")
                        .param("description", "Engineering vertical")
                        .param("iconAssetId", "icon-engineering")
                        .param("sortOrder", "1")
                        .param("availability", "ACTIVE"))
                .andExpect(status().isFound());
        var vertical = query.listVerticals().stream().filter(v -> v.code().equals(verticalCode)).findFirst().orElseThrow();

        mockMvc.perform(post("/admin/catalogue/goals")
                        .with(user("admin").roles("ADMIN")).with(csrf())
                        .param("expectedVersion", "0")
                        .param("code", goalCode)
                        .param("verticalId", vertical.id().toString())
                        .param("title", "Interview goal")
                        .param("description", "Interview preparation")
                        .param("sortOrder", "1")
                        .param("availability", "ACTIVE"))
                .andExpect(status().isFound());
        var goal = query.listGoals(vertical.id()).stream().filter(v -> v.code().equals(goalCode)).findFirst().orElseThrow();

        mockMvc.perform(post("/admin/catalogue/tracks")
                        .with(user("admin").roles("ADMIN")).with(csrf())
                        .param("expectedVersion", "0")
                        .param("code", trackCode)
                        .param("goalId", goal.id().toString())
                        .param("title", "Backend track")
                        .param("description", "Backend interviews")
                        .param("levelCode", "B2")
                        .param("careerTrackCode", "JAVA")
                        .param("sortOrder", "1")
                        .param("availability", "ACTIVE"))
                .andExpect(status().isFound());
        var track = query.listTracks(goal.id()).stream().filter(v -> v.code().equals(trackCode)).findFirst().orElseThrow();

        mockMvc.perform(post("/admin/catalogue/collections")
                        .with(user("admin").roles("ADMIN")).with(csrf())
                        .param("expectedVersion", "0")
                        .param("code", collectionCode)
                        .param("trackId", track.id().toString())
                        .param("title", "Starter collection")
                        .param("description", "Free starter block")
                        .param("accessLevel", "FREE")
                        .param("sortOrder", "1")
                        .param("availability", "ACTIVE"))
                .andExpect(status().isFound());

        assertThat(query.listCollections(track.id()))
                .anySatisfy(item -> {
                    assertThat(item.code()).isEqualTo(collectionCode);
                    assertThat(item.accessLevel()).isEqualTo("FREE");
                });

        mockMvc.perform(get("/admin/catalogue")
                        .with(user("admin").roles("ADMIN"))
                        .param("verticalId", vertical.id().toString())
                        .param("goalId", goal.id().toString())
                        .param("trackId", track.id().toString()))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Engineering")))
                .andExpect(content().string(containsString("Interview goal")))
                .andExpect(content().string(containsString("Backend track")))
                .andExpect(content().string(containsString("Starter collection")));
    }

    @Test
    void invalidFormRendersValidationAndStaleUpdateReturnsSafeConflict() throws Exception {
        mockMvc.perform(post("/admin/catalogue/verticals")
                        .with(user("admin").roles("ADMIN")).with(csrf())
                        .param("expectedVersion", "0")
                        .param("code", "")
                        .param("sectionCode", "")
                        .param("title", "")
                        .param("description", "")
                        .param("iconAssetId", "")
                        .param("sortOrder", "-1")
                        .param("availability", "ACTIVE"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Create vertical")));

        var entity = authoring.createVertical(
                new CatalogueCode("STALE" + UUID.randomUUID().toString().substring(0, 6).toUpperCase()),
                new CatalogueCode("CAREER"), "Stale test", "Conflict test", "icon", 1, AvailabilityStatus.ACTIVE);
        var snapshot = query.getVertical(entity.getId());

        mockMvc.perform(post("/admin/catalogue/verticals/{id}", entity.getId())
                        .with(user("admin").roles("ADMIN")).with(csrf())
                        .param("expectedVersion", Long.toString(snapshot.version() + 1))
                        .param("code", snapshot.code())
                        .param("sectionCode", snapshot.sectionCode())
                        .param("title", "Changed")
                        .param("description", snapshot.description())
                        .param("iconAssetId", snapshot.iconAssetId())
                        .param("sortOrder", Integer.toString(snapshot.sortOrder()))
                        .param("availability", snapshot.availability()))
                .andExpect(status().isConflict())
                .andExpect(content().string(containsString("Update conflict")))
                .andExpect(content().string(containsString("Reload and try again")));
    }
}
