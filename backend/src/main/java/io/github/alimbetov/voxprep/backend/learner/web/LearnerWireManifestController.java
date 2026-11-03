package io.github.alimbetov.voxprep.backend.learner.web;

import io.github.alimbetov.voxprep.backend.learner.application.LearnerWirePublicationService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerWirePublicationService.WireResponse;
import java.util.Map;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Exact publication JSON routes consumed by the Flutter HTTP gateways.
 * Protected by LearnerApiRoutePolicy; no authoring/JPA entity serialization.
 */
@RestController
public class LearnerWireManifestController {

    private final LearnerWirePublicationService publications;

    public LearnerWireManifestController(LearnerWirePublicationService publications) {
        this.publications = publications;
    }

    @GetMapping("/api/v1/content/manifest")
    public ResponseEntity<Map<String, Object>> root(
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        return respond(publications.root(), ifNoneMatch);
    }

    @GetMapping("/api/v1/content/packs/{packCode}/manifest")
    public ResponseEntity<Map<String, Object>> pack(
            @PathVariable String packCode,
            @RequestParam String variant,
            @RequestParam int revision,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        return respond(publications.pack(packCode, variant, revision), ifNoneMatch);
    }

    @GetMapping("/api/v1/catalogues/{kind}/revisions/{revision}")
    public ResponseEntity<Map<String, Object>> catalogue(
            @PathVariable String kind,
            @PathVariable int revision,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        return respond(publications.catalogue(kind, revision), ifNoneMatch);
    }

    private static ResponseEntity<Map<String, Object>> respond(
            WireResponse response, String ifNoneMatch) {
        // Checks are performed before 304. These wire documents are bound to one release.
        String etag = "\"" + response.checksum() + "\"";
        return LearnerHttpCache.revalidate(response.body(), etag, ifNoneMatch);
    }
}
