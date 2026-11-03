package io.github.alimbetov.voxprep.backend.asset.web;

import io.github.alimbetov.voxprep.backend.asset.application.AdminMediaService;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import java.io.IOException;
import java.net.URI;
import java.util.UUID;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/admin/api/v1/media/assets")
public class AdminMediaController {

    private final AdminMediaService service;

    public AdminMediaController(AdminMediaService service) {
        this.service = service;
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<AdminMediaService.AssetView> upload(
            @RequestParam FileAssetKind kind,
            @RequestPart("file") MultipartFile file) throws IOException {
        if (file.isEmpty()) {
            throw new IllegalArgumentException("Media file must not be empty");
        }
        AdminMediaService.AssetView asset = service.upload(kind, file.getBytes());
        return ResponseEntity.created(URI.create("/admin/api/v1/media/assets/" + asset.assetId() + "/content"))
                .body(asset);
    }

    @GetMapping(value = "/{assetId}/content")
    public ResponseEntity<byte[]> preview(@PathVariable UUID assetId) {
        AdminMediaService.AssetContent content = service.preview(assetId);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(content.mediaType()))
                .contentLength(content.bytes().length)
                .cacheControl(CacheControl.noStore())
                .header(HttpHeaders.X_CONTENT_TYPE_OPTIONS, "nosniff")
                .body(content.bytes());
    }
}
