package io.github.alimbetov.voxprep.backend.catalogue.web.mvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.model;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import io.github.alimbetov.voxprep.backend.catalogue.application.CatalogueAdminQueryService;
import io.github.alimbetov.voxprep.backend.catalogue.application.CatalogueAuthoringConflictException;
import io.github.alimbetov.voxprep.backend.catalogue.application.CatalogueAuthoringService;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CollectionAccessLevel;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningGoalEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.LearningTrackEntity;
import io.github.alimbetov.voxprep.backend.catalogue.persistence.VerticalEntity;
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
        String suffix = token();
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
                .andExpect(status().isFound())
                .andExpect(redirectedUrl("/admin/catalogue?verticalId=" + vertical.id()
                        + "&goalId=" + goal.id() + "&trackId=" + track.id()));

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
    void deepestSelectionCanonicalizesInconsistentHierarchy() throws Exception {
        var canonical = hierarchy("CAN" + token());
        var foreign = hierarchy("FOR" + token());

        mockMvc.perform(get("/admin/catalogue")
                        .with(user("admin").roles("ADMIN"))
                        .param("verticalId", foreign.vertical().getId().toString())
                        .param("goalId", foreign.goal().getId().toString())
                        .param("trackId", canonical.track().getId().toString()))
                .andExpect(status().isOk())
                .andExpect(model().attribute("selectedVerticalId", canonical.vertical().getId()))
                .andExpect(model().attribute("selectedGoalId", canonical.goal().getId()))
                .andExpect(model().attribute("selectedTrackId", canonical.track().getId()));
    }

    @Test
    void forgedParentOnUpdateIsRejectedAndOriginalParentRemains() throws Exception {
        var original = hierarchy("ORG" + token());
        var foreign = hierarchy("ALT" + token());
        var goal = query.getGoal(original.goal().getId());

        mockMvc.perform(post("/admin/catalogue/goals/{id}", goal.id())
                        .with(user("admin").roles("ADMIN")).with(csrf())
                        .param("expectedVersion", Long.toString(goal.version()))
                        .param("code", goal.code())
                        .param("verticalId", foreign.vertical().getId().toString())
                        .param("title", "Forged move")
                        .param("description", goal.description())
                        .param("sortOrder", Integer.toString(goal.sortOrder()))
                        .param("availability", goal.availability()))
                .andExpect(status().isConflict())
                .andExpect(content().string(containsString("Update conflict")));

        assertThat(query.getGoal(goal.id()).parentId()).isEqualTo(original.vertical().getId());
    }

    @Test
    void trackAndCollectionParentsAreImmutableAtApplicationBoundary() {
        var original = hierarchy("IMM" + token());
        var foreign = hierarchy("FIM" + token());
        var track = query.getTrack(original.track().getId());

        assertThatThrownBy(() -> authoring.updateTrack(
                        track.id(), track.version(), foreign.goal().getId(), track.title(), track.description(),
                        new CatalogueCode(track.levelCode()), new CatalogueCode(track.careerTrackCode()),
                        track.sortOrder(), AvailabilityStatus.valueOf(track.availability())))
                .isInstanceOf(CatalogueAuthoringConflictException.class);
        assertThat(query.getTrack(track.id()).parentId()).isEqualTo(original.goal().getId());

        var collectionEntity = authoring.createCollection(
                new CatalogueCode("COL" + token()), original.track().getId(), "Immutable collection",
                "Collection for parent immutability acceptance", CollectionAccessLevel.FREE, 1,
                AvailabilityStatus.ACTIVE);
        var collection = query.getCollection(collectionEntity.getId());

        assertThatThrownBy(() -> authoring.updateCollection(
                        collection.id(), collection.version(), foreign.track().getId(), collection.title(),
                        collection.description(), CollectionAccessLevel.valueOf(collection.accessLevel()),
                        collection.sortOrder(), AvailabilityStatus.valueOf(collection.availability())))
                .isInstanceOf(CatalogueAuthoringConflictException.class);
        assertThat(query.getCollection(collection.id()).parentId()).isEqualTo(original.track().getId());
    }

    @Test
    void invalidCatalogueCodeIsRejectedByMvcValidation() throws Exception {
        mockMvc.perform(post("/admin/catalogue/verticals")
                        .with(user("admin").roles("ADMIN")).with(csrf())
                        .param("expectedVersion", "0")
                        .param("code", "lower-case")
                        .param("sectionCode", "CAREER")
                        .param("title", "Invalid code")
                        .param("description", "Must stay in form validation")
                        .param("iconAssetId", "icon")
                        .param("sortOrder", "1")
                        .param("availability", "ACTIVE"))
                .andExpect(status().isOk())
                .andExpect(model().attributeHasFieldErrors("form", "code"))
                .andExpect(content().string(containsString("Create vertical")));
    }

    @Test
    void duplicateCatalogueCodeReturnsSafeConflict() throws Exception {
        String code = "DUP" + token();
        authoring.createVertical(
                new CatalogueCode(code), new CatalogueCode("CAREER"), "Existing", "Existing vertical", "icon", 1,
                AvailabilityStatus.ACTIVE);

        mockMvc.perform(post("/admin/catalogue/verticals")
                        .with(user("admin").roles("ADMIN")).with(csrf())
                        .param("expectedVersion", "0")
                        .param("code", code)
                        .param("sectionCode", "CAREER")
                        .param("title", "Duplicate")
                        .param("description", "Duplicate vertical")
                        .param("iconAssetId", "icon")
                        .param("sortOrder", "2")
                        .param("availability", "ACTIVE"))
                .andExpect(status().isConflict())
                .andExpect(content().string(containsString("Update conflict")))
                .andExpect(content().string(containsString("Reload and try again")));
    }

    @Test
    void catalogueMutationWithoutCsrfIsForbidden() throws Exception {
        mockMvc.perform(post("/admin/catalogue/verticals")
                        .with(user("admin").roles("ADMIN"))
                        .param("expectedVersion", "0")
                        .param("code", "CSRF" + token())
                        .param("sectionCode", "CAREER")
                        .param("title", "CSRF")
                        .param("description", "CSRF rejection")
                        .param("iconAssetId", "icon")
                        .param("sortOrder", "1")
                        .param("availability", "ACTIVE"))
                .andExpect(status().isForbidden());
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
                new CatalogueCode("STALE" + token()),
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

    private Hierarchy hierarchy(String prefix) {
        VerticalEntity vertical = authoring.createVertical(
                new CatalogueCode(prefix + "V"), new CatalogueCode("CAREER"), prefix + " vertical",
                "Vertical for MVC hardening acceptance", "icon", 1, AvailabilityStatus.ACTIVE);
        LearningGoalEntity goal = authoring.createGoal(
                new CatalogueCode(prefix + "G"), vertical.getId(), prefix + " goal",
                "Goal for MVC hardening acceptance", 1, AvailabilityStatus.ACTIVE);
        LearningTrackEntity track = authoring.createTrack(
                new CatalogueCode(prefix + "T"), goal.getId(), prefix + " track",
                "Track for MVC hardening acceptance", new CatalogueCode("B2"), new CatalogueCode("JAVA"), 1,
                AvailabilityStatus.ACTIVE);
        return new Hierarchy(vertical, goal, track);
    }

    private static String token() {
        return UUID.randomUUID().toString().replace("-", "").substring(0, 8).toUpperCase();
    }

    private record Hierarchy(VerticalEntity vertical, LearningGoalEntity goal, LearningTrackEntity track) {}
}
