package io.github.alimbetov.voxprep.backend.asset.web;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import io.github.alimbetov.voxprep.backend.asset.application.MediaLibraryService;
import io.github.alimbetov.voxprep.backend.asset.domain.ContentAssetRole;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class MediaPickerControllerTest {
    @Test
    void invalidImageReturnsSafe400InsteadOfServerError() throws Exception {
        var library = mock(MediaLibraryService.class);
        when(library.upload(eq(ContentAssetRole.COVER_IMAGE), eq("image/png"), any(byte[].class)))
                .thenThrow(new IllegalArgumentException("Internal signature details"));
        var mvc = MockMvcBuilders.standaloneSetup(new MediaLibraryMvcController(library)).build();
        mvc.perform(multipart("/admin/media/images")
                        .file(new MockMultipartFile("file", "bad.png", "image/png", new byte[]{1, 2, 3}))
                        .param("role", "COVER_IMAGE"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        "Select a valid library image or upload a PNG, JPEG or WebP within the size limit."));
    }
}
