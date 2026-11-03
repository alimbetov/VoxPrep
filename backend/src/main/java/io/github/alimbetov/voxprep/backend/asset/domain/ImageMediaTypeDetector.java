package io.github.alimbetov.voxprep.backend.asset.domain;

/** Detects the supported image type from file signatures rather than caller-supplied headers. */
public final class ImageMediaTypeDetector {

    private ImageMediaTypeDetector() {
    }

    public static DetectedImage detect(byte[] bytes) {
        if (bytes == null || bytes.length < 3) {
            throw unsupported();
        }
        if ((bytes[0] & 0xff) == 0xff && (bytes[1] & 0xff) == 0xd8 && (bytes[2] & 0xff) == 0xff) {
            return new DetectedImage("image/jpeg", "jpg");
        }
        if (bytes.length >= 8
                && (bytes[0] & 0xff) == 0x89
                && bytes[1] == 0x50 && bytes[2] == 0x4e && bytes[3] == 0x47
                && bytes[4] == 0x0d && bytes[5] == 0x0a && bytes[6] == 0x1a && bytes[7] == 0x0a) {
            return new DetectedImage("image/png", "png");
        }
        if (bytes.length >= 12
                && ascii(bytes, 0, "RIFF")
                && ascii(bytes, 8, "WEBP")) {
            return new DetectedImage("image/webp", "webp");
        }
        throw unsupported();
    }

    private static boolean ascii(byte[] bytes, int offset, String value) {
        for (int index = 0; index < value.length(); index++) {
            if (bytes[offset + index] != (byte) value.charAt(index)) {
                return false;
            }
        }
        return true;
    }

    private static IllegalArgumentException unsupported() {
        return new IllegalArgumentException("Unsupported or unrecognized image payload");
    }

    public record DetectedImage(String mediaType, String extension) {
    }
}
