package io.github.alimbetov.voxprep.backend.learner.application;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

class FlutterPublicationCanonicalHashTest {
    private final ObjectMapper json = new ObjectMapper();

    @Test
    void rootMatchesIndependentFlutterC44FixtureVector() {
        var manifest = new LinkedHashMap<String, Object>();
        manifest.put("schemaVersion", 1);
        manifest.put("contentVersion", 109);
        manifest.put("minimumAppContractVersion", 1);
        manifest.put("publishedAt", "2026-10-31T15:00:00Z");
        manifest.put("packs", List.of(Map.of(
                "variant", "canonical", "checksum", "c".repeat(64),
                "revision", 8, "code", "JAVA_SENIOR")));
        manifest.put("practiceTests", List.of());
        manifest.put("catalogues", List.of());
        manifest.put("localeFallbacks", List.of());
        manifest.put("tombstones", List.of());
        assertThat(FlutterPublicationCanonicalHash.root(json, manifest))
                .isEqualTo("dfe4533c700f5bb10c1d44ae186cc4e4a360b37071e9127bf408fff571fff660");
    }

    @Test
    void packMatchesIndependentFlutterC44FixtureVector() {
        var manifest = new LinkedHashMap<String, Object>();
        manifest.put("schemaVersion", 1);
        manifest.put("code", "JAVA_SENIOR");
        manifest.put("variant", "canonical");
        manifest.put("revision", 8);
        manifest.put("contents", List.of(Map.of(
                "publishedAt", "2026-10-31T14:00:00Z", "sortOrder", 1,
                "checksum", "b".repeat(64), "revision", 1,
                "contentType", "interview", "contentCode", "JAVA_Q_001")));
        manifest.put("localizations", List.of());
        manifest.put("assets", List.of(Map.of(
                "mediaType", "audio/mpeg", "deliveryKey", "audio/q1-r1.mp3",
                "assetId", "audio-q1", "requiredOffline", true,
                "sizeBytes", 1024, "checksumSha256", "c".repeat(64))));
        manifest.put("contentAssets", List.of(Map.of(
                "role", "promptAudio", "contentRevision", 1, "assetId", "audio-q1",
                "contentCode", "JAVA_Q_001", "contentType", "interview")));
        assertThat(FlutterPublicationCanonicalHash.pack(json, manifest))
                .isEqualTo("b7bdbb7f48a9ffdb8b53d572818e6eb892471d16eb6d9de29527549245ac30cd");
    }

    @Test
    void nestedMapKeyOrderCannotAlterTheFlutterManifestDigest() {
        var manifest = new LinkedHashMap<String, Object>();
        manifest.put("schemaVersion", 1);
        manifest.put("contentVersion", 109);
        manifest.put("minimumAppContractVersion", 1);
        manifest.put("publishedAt", "2026-10-31T15:00:00Z");
        manifest.put("packs", List.of(Map.of(
                "checksum", "c".repeat(64), "code", "JAVA_SENIOR",
                "revision", 8, "variant", "canonical")));
        manifest.put("practiceTests", List.of());
        manifest.put("catalogues", List.of());
        manifest.put("localeFallbacks", List.of());
        manifest.put("tombstones", List.of());
        assertThat(FlutterPublicationCanonicalHash.root(json, manifest))
                .isEqualTo("dfe4533c700f5bb10c1d44ae186cc4e4a360b37071e9127bf408fff571fff660");
    }
}
