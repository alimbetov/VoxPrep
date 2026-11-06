package io.github.alimbetov.voxprep.backend.asset.web;

import io.github.alimbetov.voxprep.backend.asset.application.MediaLibraryService;
import io.github.alimbetov.voxprep.backend.asset.domain.ContentAssetRole;
import io.github.alimbetov.voxprep.backend.content.web.AdminContentStudioMvc;
import java.util.UUID;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@AdminContentStudioMvc
@Controller
@RequestMapping("/admin/media")
public class MediaLibraryMvcController {
    private final MediaLibraryService library;

    public MediaLibraryMvcController(MediaLibraryService library) {
        this.library = library;
    }

    @ExceptionHandler(IllegalArgumentException.class)
    @ResponseBody
    public ResponseEntity<java.util.Map<String, String>> invalidImage(IllegalArgumentException exception) {
        return ResponseEntity.badRequest().body(java.util.Map.of("message",
                "Select a valid library image or upload a PNG, JPEG or WebP within the size limit."));
    }

    @GetMapping("/images")
    @ResponseBody
    public java.util.List<ImageChoice> images(@RequestParam(defaultValue = "COVER_IMAGE") ContentAssetRole role,
            @RequestParam(defaultValue = "0") int page) {
        return library.list(role, page).stream().map(ImageChoice::from).toList();
    }

    @PostMapping("/images")
    @ResponseBody
    public ImageChoice uploadImage(@RequestParam ContentAssetRole role,
            @RequestParam("file") MultipartFile file) throws java.io.IOException {
        if (file.isEmpty() || file.getSize() > 10L * 1024 * 1024) {
            throw new IllegalArgumentException("Invalid image size");
        }
        return ImageChoice.from(library.upload(role, file.getContentType(), file.getBytes()));
    }

    public record ImageChoice(UUID id, String mediaType, long sizeBytes, String previewUrl) {
        static ImageChoice from(io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity asset) {
            return new ImageChoice(asset.getId(), asset.getMediaType(), asset.getSizeBytes(),
                    "/admin/media/" + asset.getId() + "/preview");
        }
    }

    @GetMapping
    public String list(@RequestParam UUID revisionId,
            @RequestParam(defaultValue = "COVER_IMAGE") ContentAssetRole role,
            @RequestParam(defaultValue = "0") int page, Model model) {
        if (role.audio()) throw new IllegalArgumentException("Not an image role");
        model.addAttribute("activeSection", "content");
        model.addAttribute("revisionId", revisionId);
        model.addAttribute("role", role);
        model.addAttribute("page", page);
        model.addAttribute("assets", library.list(role, page));
        return "admin/media/index";
    }

    @PostMapping("/upload")
    public String upload(@RequestParam UUID revisionId,
            @RequestParam ContentAssetRole role,
            @RequestParam("file") MultipartFile file,
            RedirectAttributes messages) throws java.io.IOException {
        if (file.isEmpty() || file.getSize() > 10L * 1024 * 1024) {
            throw new IllegalArgumentException("Invalid image size");
        }
        var asset = library.upload(role, file.getContentType(), file.getBytes());
        messages.addFlashAttribute("flashSuccess", "Image ready: " + asset.getId());
        return picker(revisionId, role);
    }

    @PostMapping("/bind")
    public String bind(@RequestParam UUID revisionId,
            @RequestParam ContentAssetRole role,
            @RequestParam UUID assetId,
            RedirectAttributes messages) {
        library.bind(revisionId, role, assetId);
        messages.addFlashAttribute("flashSuccess", "Image linked to draft.");
        return "redirect:/admin/content/revisions/" + revisionId + "/edit";
    }

    @GetMapping("/{assetId}/preview")
    public ResponseEntity<byte[]> preview(@PathVariable UUID assetId) {
        var asset = library.requireReadyImage(assetId);
        byte[] bytes = library.preview(assetId);
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .contentType(MediaType.parseMediaType(asset.getMediaType()))
                .body(bytes);
    }

    private static String picker(UUID revisionId, ContentAssetRole role) {
        return "redirect:/admin/media?revisionId=" + revisionId + "&role=" + role.name();
    }
}
