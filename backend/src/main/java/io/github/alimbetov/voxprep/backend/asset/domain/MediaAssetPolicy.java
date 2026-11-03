package io.github.alimbetov.voxprep.backend.asset.domain;

import java.util.Set;

/** Policy for user-facing image assets. SVG is intentionally excluded because it can contain active content. */
public final class MediaAssetPolicy {

    public static final long COVER_IMAGE_MAX_BYTES = 5L * 1024 * 1024;
    public static final long CONTENT_IMAGE_MAX_BYTES = 10L * 1024 * 1024;

    private static final Set<String> IMAGE_MEDIA_TYPES = Set.of(
            "image/jpeg",
            "image/png",
            "image/webp");

    private MediaAssetPolicy() {
    }

    public static void validate(FileAssetKind kind, String mediaType, long sizeBytes) {
        if (kind != FileAssetKind.COVER_IMAGE && kind != FileAssetKind.CONTENT_IMAGE) {
            return;
        }
        if (!IMAGE_MEDIA_TYPES.contains(mediaType)) {
            throw new IllegalArgumentException("Unsupported image media type: " + mediaType);
        }
        long maxBytes = kind == FileAssetKind.COVER_IMAGE
                ? COVER_IMAGE_MAX_BYTES
                : CONTENT_IMAGE_MAX_BYTES;
        if (sizeBytes < 1 || sizeBytes > maxBytes) {
            throw new IllegalArgumentException(kind + " size must be between 1 and " + maxBytes + " bytes");
        }
    }
}
