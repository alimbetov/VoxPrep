package io.github.alimbetov.voxprep.backend.learner.web;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.HexFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

public final class LearnerHttpCache {

    public static final String CACHE_CONTROL = "private, max-age=0, must-revalidate";
    private static final String ETAG_DOMAIN = "voxprep-learner-http-etag-v1";

    private LearnerHttpCache() {}

    public static String weakEtag(String resourceKind, Object... components) {
        MessageDigest digest = sha256();
        update(digest, ETAG_DOMAIN);
        update(digest, resourceKind);
        for (Object component : components) {
            update(digest, component == null ? null : component.toString());
        }
        return "W/\"" + HexFormat.of().formatHex(digest.digest()) + "\"";
    }

    public static <T> ResponseEntity<T> revalidate(T body, String etag, String ifNoneMatch) {
        if (matches(ifNoneMatch, etag)) {
            return ResponseEntity.status(HttpStatus.NOT_MODIFIED)
                    .header(HttpHeaders.ETAG, etag)
                    .header(HttpHeaders.CACHE_CONTROL, CACHE_CONTROL)
                    .build();
        }
        return ResponseEntity.ok()
                .header(HttpHeaders.ETAG, etag)
                .header(HttpHeaders.CACHE_CONTROL, CACHE_CONTROL)
                .body(body);
    }

    public static boolean matches(String ifNoneMatch, String currentEtag) {
        if (ifNoneMatch == null || ifNoneMatch.isBlank()) {
            return false;
        }
        return Arrays.stream(ifNoneMatch.split(","))
                .map(String::trim)
                .anyMatch(candidate -> "*".equals(candidate)
                        || weakValue(candidate).equals(weakValue(currentEtag)));
    }

    private static void update(MessageDigest digest, String value) {
        if (value == null) {
            digest.update("-1:".getBytes(StandardCharsets.UTF_8));
            return;
        }
        byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
        digest.update(Integer.toString(bytes.length).getBytes(StandardCharsets.UTF_8));
        digest.update((byte) ':');
        digest.update(bytes);
    }

    private static String weakValue(String etag) {
        String value = etag == null ? "" : etag.trim();
        if (value.startsWith("W/")) {
            value = value.substring(2).trim();
        }
        return value;
    }

    private static MessageDigest sha256() {
        try {
            return MessageDigest.getInstance("SHA-256");
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 must be available", exception);
        }
    }
}
