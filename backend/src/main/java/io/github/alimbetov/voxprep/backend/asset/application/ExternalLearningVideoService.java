package io.github.alimbetov.voxprep.backend.asset.application;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;
import java.util.regex.Pattern;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Curated video link, not a FileAsset; never downloads arbitrary URLs. */
@Service
public class ExternalLearningVideoService {
    private static final Pattern YOUTUBE_ID = Pattern.compile("[A-Za-z0-9_-]{11}");
    private final JdbcTemplate jdbc;

    public ExternalLearningVideoService(JdbcTemplate jdbc) {
        this.jdbc = Objects.requireNonNull(jdbc);
    }

    public record Video(String provider, String providerVideoId, String title) {
        public String url() {
            return "https://www.youtube.com/watch?v=" + providerVideoId;
        }
    }

    public static String parseYouTubeId(String input) {
        if (input == null || input.length() > 512 || input.isBlank()
                || !input.equals(input.strip())) {
            throw new IllegalArgumentException("Invalid video URL");
        }
        final URI uri;
        try {
            uri = new URI(input);
        } catch (URISyntaxException error) {
            throw new IllegalArgumentException("Invalid video URL", error);
        }
        if (!"https".equals(uri.getScheme()) || uri.getHost() == null
                || uri.getRawUserInfo() != null || uri.getPort() != -1
                || uri.getRawFragment() != null) {
            throw new IllegalArgumentException("Only HTTPS YouTube URLs are supported");
        }
        String id;
        if ("youtu.be".equals(uri.getHost())) {
            if (uri.getRawQuery() != null || uri.getRawPath() == null
                    || !uri.getRawPath().matches("/[A-Za-z0-9_-]{11}")) {
                throw new IllegalArgumentException("Invalid YouTube short URL");
            }
            id = uri.getRawPath().substring(1);
        } else if ("youtube.com".equals(uri.getHost()) || "www.youtube.com".equals(uri.getHost())) {
            if (!"/watch".equals(uri.getRawPath()) || uri.getRawQuery() == null
                    || !uri.getRawQuery().matches("v=[A-Za-z0-9_-]{11}")) {
                throw new IllegalArgumentException("Invalid YouTube watch URL");
            }
            id = uri.getRawQuery().substring(2);
        } else {
            throw new IllegalArgumentException("Unsupported video provider");
        }
        if (!YOUTUBE_ID.matcher(id).matches()) {
            throw new IllegalArgumentException("Invalid video ID");
        }
        return id;
    }

    @Transactional(readOnly = true)
    public Optional<Video> find(UUID revisionId) {
        return jdbc.query("""
                SELECT provider, provider_video_id, title
                  FROM app.content_external_video WHERE content_revision_id=?
                """, (rs, index) -> new Video(rs.getString(1), rs.getString(2), rs.getString(3)),
                revisionId).stream().findFirst();
    }

    /** Immutable, transactionally captured on the DRAFT/APPROVED -> PUBLISHED boundary. */
    @Transactional(readOnly = true)
    public Optional<Video> findPublished(UUID revisionId) {
        return jdbc.query("""
                SELECT provider, provider_video_id, title
                  FROM app.content_external_video_snapshot WHERE content_revision_id=?
                """, (rs, index) -> new Video(rs.getString(1), rs.getString(2), rs.getString(3)),
                revisionId).stream().findFirst();
    }

    @Transactional
    public void save(UUID revisionId, String url, String title) {
        Objects.requireNonNull(revisionId);
        String videoId = parseYouTubeId(url);
        String safeTitle = title == null ? "" : title.strip();
        if (safeTitle.isEmpty() || safeTitle.length() > 160) {
            throw new IllegalArgumentException("Video title must contain 1–160 characters");
        }
        requireDraft(revisionId);
        jdbc.update("""
                INSERT INTO app.content_external_video
                    (content_revision_id, provider, provider_video_id, title)
                VALUES (?, 'YOUTUBE', ?, ?)
                ON CONFLICT (content_revision_id) DO UPDATE SET
                    provider_video_id=EXCLUDED.provider_video_id,
                    title=EXCLUDED.title, updated_at=CURRENT_TIMESTAMP
                """, revisionId, videoId, safeTitle);
    }

    @Transactional
    public void remove(UUID revisionId) {
        requireDraft(revisionId);
        jdbc.update("DELETE FROM app.content_external_video WHERE content_revision_id=?", revisionId);
    }

    private void requireDraft(UUID revisionId) {
        var states = jdbc.query(
                "SELECT lifecycle FROM app.content_revision WHERE id=? FOR UPDATE",
                (rs, row) -> rs.getString(1), revisionId);
        if (states.size() != 1 || !"DRAFT".equals(states.get(0))) {
            throw new IllegalStateException("External video is editable only in DRAFT");
        }
    }
}
