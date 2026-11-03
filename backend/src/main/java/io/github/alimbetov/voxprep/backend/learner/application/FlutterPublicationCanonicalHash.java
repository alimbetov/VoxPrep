package io.github.alimbetov.voxprep.backend.learner.application;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import tools.jackson.databind.ObjectMapper;

/**
 * Exact C4.4 Flutter publication projection. Do not hash arbitrary JSON map order:
 * Dart's PublicationManifestCanonicalizer uses a fixed key order at EVERY level.
 */
public final class FlutterPublicationCanonicalHash {

    private static final List<String> ROOT = List.of(
            "schemaVersion", "contentVersion", "minimumAppContractVersion",
            "publishedAt", "packs", "practiceTests", "catalogues",
            "localeFallbacks", "tombstones");
    private static final List<String> PACK = List.of(
            "schemaVersion", "code", "variant", "revision",
            "contents", "localizations", "assets", "contentAssets");

    private FlutterPublicationCanonicalHash() {
    }

    public static String root(ObjectMapper mapper, Map<String, Object> wire) {
        var body = project(wire, ROOT);
        body.put("packs", projectList(wire, "packs", List.of("code", "variant", "revision", "checksum")));
        body.put("practiceTests", projectList(
                wire, "practiceTests", List.of("practiceTestCode", "revision", "checksum")));
        body.put("catalogues", projectList(wire, "catalogues", List.of("kind", "revision", "checksum")));
        body.put("localeFallbacks", projectList(wire, "localeFallbacks", List.of("locale", "fallbackLocales")));
        body.put("tombstones", projectList(
                wire, "tombstones", List.of("contentCode", "contentType", "revision", "reason")));
        return sha256(mapper, body);
    }

    public static String pack(ObjectMapper mapper, Map<String, Object> wire) {
        var body = project(wire, PACK);
        body.put("contents", projectList(wire, "contents", List.of(
                "contentCode", "contentType", "revision", "checksum", "sortOrder", "publishedAt")));
        body.put("localizations", projectList(wire, "localizations", List.of(
                "contentCode", "contentType", "contentRevision", "locale",
                "localizationRevision", "checksum")));
        body.put("assets", projectList(wire, "assets", List.of(
                "assetId", "checksumSha256", "deliveryKey", "sizeBytes", "mediaType",
                "requiredOffline")));
        body.put("contentAssets", projectList(wire, "contentAssets", List.of(
                "contentCode", "contentType", "contentRevision", "assetId", "role")));
        return sha256(mapper, body);
    }

    private static List<LinkedHashMap<String, Object>> projectList(
            Map<String, Object> source, String field, List<String> keys) {
        if (!(source.get(field) instanceof List<?> raw)) {
            throw new IllegalArgumentException("manifest list is missing: " + field);
        }
        return raw.stream().map(item -> {
            if (!(item instanceof Map<?, ?> map)) {
                throw new IllegalArgumentException("manifest list member is not an object: " + field);
            }
            return project(map, keys);
        }).toList();
    }

    private static LinkedHashMap<String, Object> project(Map<?, ?> source, List<String> keys) {
        var expected = new java.util.HashSet<>(keys);
        if (!source.keySet().containsAll(expected)) {
            throw new IllegalArgumentException("canonical manifest is missing required fields");
        }
        var result = new LinkedHashMap<String, Object>();
        for (String key : keys) {
            result.put(key, source.get(key));
        }
        return result;
    }

    private static String sha256(ObjectMapper mapper, Map<String, Object> body) {
        try {
            byte[] bytes = mapper.writeValueAsString(body).getBytes(StandardCharsets.UTF_8);
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 unavailable", exception);
        }
    }
}
