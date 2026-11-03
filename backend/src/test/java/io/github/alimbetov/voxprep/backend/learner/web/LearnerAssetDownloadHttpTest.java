package io.github.alimbetov.voxprep.backend.learner.web;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import io.github.alimbetov.voxprep.backend.asset.application.LearnerMediaService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerAssetResolutionService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerPremiumAccessDeniedException;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class LearnerAssetDownloadHttpTest {
    private final UUID id = UUID.fromString("11111111-1111-4111-8111-111111111111");
    private final LearnerAssetResolutionService resolution = mock(LearnerAssetResolutionService.class);
    private final LearnerMediaService media = mock(LearnerMediaService.class);

    @Test
    void downloadsPublishedReadyImageViaFlutterEndpoint() throws Exception {
        var descriptor = new LearnerMediaService.MediaDescriptor(id, "bucket", "key", "image/png",
                3, "b".repeat(64), "\"" + "b".repeat(64) + "\"");
        when(resolution.requirePublished(id)).thenReturn(descriptor);
        when(media.read(descriptor)).thenReturn(new LearnerMediaService.MediaContent(
                "image/png", new byte[] {1, 2, 3}));
        var mvc = MockMvcBuilders.standaloneSetup(
                new LearnerAssetDownloadController(resolution, media))
                .setControllerAdvice(new LearnerContentExceptionHandler()).build();

        mvc.perform(get("/api/v1/media/assets/" + id + "/content"))
                .andExpect(status().isOk())
                .andExpect(header().string("X-Content-Type-Options", "nosniff"))
                .andExpect(content().contentType("image/png"))
                .andExpect(content().bytes(new byte[] {1, 2, 3}));
    }

    @Test
    void deniesPremiumAssetBeforeCacheOrStorageRead() throws Exception {
        doThrow(new LearnerPremiumAccessDeniedException()).when(resolution).requirePublished(id);
        var mvc = MockMvcBuilders.standaloneSetup(
                new LearnerAssetDownloadController(resolution, media))
                .setControllerAdvice(new LearnerContentExceptionHandler()).build();

        mvc.perform(get("/api/v1/media/assets/" + id + "/content")
                        .header("If-None-Match", "*"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("PREMIUM_UNLOCK_REQUIRED"));
        verifyNoInteractions(media);
    }
}
