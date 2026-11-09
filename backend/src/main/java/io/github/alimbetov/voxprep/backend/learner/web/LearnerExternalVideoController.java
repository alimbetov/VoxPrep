package io.github.alimbetov.voxprep.backend.learner.web;

import io.github.alimbetov.voxprep.backend.asset.application.ExternalLearningVideoService;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentAccessPolicy;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerContentService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerWirePublicationService;
import io.github.alimbetov.voxprep.backend.learner.application.LearnerWireSnapshotUnavailableException;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Optional v2 metadata route. Existing strict content payload and binary
 * image/audio contracts stay byte-for-byte unchanged. FREE/FULL access is
 * checked before querying the exact CURRENT content revision.
 */
@RestController
@RequestMapping("/api/v2/content")
public class LearnerExternalVideoController {
    private final LearnerContentAccessPolicy access;
    private final LearnerContentService content;
    private final ContentRevisionRepository revisions;
    private final ExternalLearningVideoService videos;
    private final LearnerWirePublicationService wirePublications;
    private final boolean enabled;

    public LearnerExternalVideoController(LearnerContentAccessPolicy access,
            LearnerContentService content, ContentRevisionRepository revisions,
            ExternalLearningVideoService videos,
            LearnerWirePublicationService wirePublications,
            @Value("${voxprep.media.external-video.enabled:false}") boolean enabled) {
        this.access = access;
        this.content = content;
        this.revisions = revisions;
        this.videos = videos;
        this.wirePublications = wirePublications;
        this.enabled = enabled;
    }

    public record Projection(int schemaVersion, String contentType,
            String contentCode, int revision, long contentVersion, String rootSha256,
            String provider, String providerVideoId, String title, String url) {}

    @GetMapping("/{contentType}/{contentCode}/external-video")
    @Transactional(readOnly = true, isolation = Isolation.REPEATABLE_READ)
    public ResponseEntity<Projection> read(
            @PathVariable String contentType, @PathVariable String contentCode) {
        access.requireAccessible(contentType, contentCode);
        if (!enabled) {
            return ResponseEntity.noContent().cacheControl(CacheControl.noStore()).build();
        }
        var snapshot = content.get(contentType, contentCode);
        UUID id = revisions.findIdByExactIdentity(
                snapshot.contentCode(), snapshot.contentType(), snapshot.revisionNumber())
                .orElseThrow(() -> new IllegalStateException("Exact published revision missing"));
        return videos.findPublished(id).map(video -> {
            // Share one MVCC snapshot across authorization, exact content and
            // verified ROOT reads. Never substitute the legacy candidate SHA.
            var root = wirePublications.root();
            if (!(root.body().get("contentVersion") instanceof Number version)
                    || version.longValue() != snapshot.contentVersion()) {
                throw new LearnerWireSnapshotUnavailableException("Video and ROOT publication versions differ");
            }
            return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(new Projection(1, snapshot.contentType(),
                        snapshot.contentCode(), snapshot.revisionNumber(),
                        snapshot.contentVersion(), root.checksum(),
                        video.provider(), video.providerVideoId(), video.title(), video.url()));
        })
                .orElseGet(() -> ResponseEntity.noContent()
                        .cacheControl(CacheControl.noStore()).build());
    }
}
