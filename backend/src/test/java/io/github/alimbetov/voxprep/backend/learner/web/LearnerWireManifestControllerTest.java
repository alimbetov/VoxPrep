package io.github.alimbetov.voxprep.backend.learner.web;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import io.github.alimbetov.voxprep.backend.learner.application.LearnerWirePublicationService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerWireSnapshotUnavailableException;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class LearnerWireManifestControllerTest {
    private final LearnerWirePublicationService service = mock(LearnerWirePublicationService.class);
    private static final String DIGEST = "a".repeat(64);

    @Test
    void servesRootWithChecksumEtagAndSupports304() throws Exception {
        when(service.root()).thenReturn(new LearnerWirePublicationService.WireResponse(
                Map.of("schemaVersion", 2, "checksum", DIGEST), DIGEST));
        var mvc = MockMvcBuilders.standaloneSetup(new LearnerWireManifestController(service))
                .setControllerAdvice(new LearnerContentExceptionHandler()).build();
        mvc.perform(get("/api/v1/content/manifest"))
                .andExpect(status().isOk())
                .andExpect(header().string("ETag", "\"" + DIGEST + "\""))
                .andExpect(jsonPath("$.checksum").value(DIGEST));
        mvc.perform(get("/api/v1/content/manifest").header("If-None-Match", "\""+DIGEST+"\""))
                .andExpect(status().isNotModified());
    }

    @Test
    void exposesFlutterExactPackAndCatalogueRoutes() throws Exception {
        when(service.pack("COLLECTION_A", "canonical", 3)).thenReturn(
                new LearnerWirePublicationService.WireResponse(
                        Map.of("code", "COLLECTION_A", "checksum", DIGEST), DIGEST));
        when(service.catalogue("learning-collections", 3)).thenReturn(
                new LearnerWirePublicationService.WireResponse(
                        Map.of("kind", "learning-collections", "checksum", DIGEST), DIGEST));
        var mvc = MockMvcBuilders.standaloneSetup(new LearnerWireManifestController(service))
                .setControllerAdvice(new LearnerContentExceptionHandler()).build();
        mvc.perform(get("/api/v1/content/packs/COLLECTION_A/manifest")
                        .param("variant", "canonical").param("revision", "3"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.code").value("COLLECTION_A"));
        mvc.perform(get("/api/v1/catalogues/learning-collections/revisions/3"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.kind").value("learning-collections"));
    }

    @Test
    void missingImmutableWireDocumentReturns503NotMadeUpManifest() throws Exception {
        when(service.root()).thenThrow(new LearnerWireSnapshotUnavailableException("no frozen root"));
        var mvc = MockMvcBuilders.standaloneSetup(new LearnerWireManifestController(service))
                .setControllerAdvice(new LearnerContentExceptionHandler()).build();
        mvc.perform(get("/api/v1/content/manifest"))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.code").value("LEARNER_WIRE_SNAPSHOT_UNAVAILABLE"));
    }
}
