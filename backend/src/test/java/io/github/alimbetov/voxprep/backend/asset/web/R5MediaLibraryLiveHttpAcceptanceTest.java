package io.github.alimbetov.voxprep.backend.asset.web;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.alimbetov.voxprep.backend.asset.domain.ContentAssetRole;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.ContentAssetBindingRepository;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionRepository;
import io.github.alimbetov.voxprep.backend.content.persistence.PhraseContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.AvailabilityStatus;
import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import java.net.CookieManager;
import java.net.CookiePolicy;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Base64;
import java.util.List;
import java.util.UUID;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

/** Real HTTP transport + form session/CSRF + live PostgreSQL/RustFS. Not MockMvc. */
@ActiveProfiles("test")
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@EnabledIfSystemProperty(named = "voxprep.r5.enabled", matches = "true")
class R5MediaLibraryLiveHttpAcceptanceTest {
    private static final byte[] PNG = Base64.getDecoder().decode(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/5a0AAAAASUVORK5CYII=");
    private static final Pattern CSRF = Pattern.compile(
            "name=\"_csrf\"[^>]*value=\"([^\"]+)\"|name=\"_csrf\"[^>]*content=\"([^\"]+)\"");
    private static final Pattern UUID_PATTERN = Pattern.compile(
            "Image ready: ([a-f0-9-]{36})");

    @Value("${local.server.port}") int port;
    @Value("${voxprep.security.admin.username}") String adminUsername;
    @Value("${voxprep.security.admin.password}") String adminPassword;

    @Autowired ContentRevisionRepository revisions;
    @Autowired FileAssetRepository files;
    @Autowired ContentAssetBindingRepository bindings;

    @Test
    void authenticatedHttpUploadReusesImageAndBindsTwoDrafts() throws Exception {
        // Fixture creation is intentionally separate from the HTTP actions under test.
        // R5 editor creation and publication still require their own independent acceptance.
        var first = revisions.saveAndFlush(draft("R5_IMG_" + UUID.randomUUID().toString().replace("-", "")));
        var second = revisions.saveAndFlush(draft("R5_IMG_" + UUID.randomUUID().toString().replace("-", "")));
        var cookies = new CookieManager(null, CookiePolicy.ACCEPT_ALL);
        try (var http = HttpClient.newBuilder().cookieHandler(cookies)
                .connectTimeout(Duration.ofSeconds(5))
                .followRedirects(HttpClient.Redirect.NEVER).build()) {
            URI base = URI.create("http://127.0.0.1:" + port);
            var anonymous = get(http, base.resolve("/admin/media?revisionId=" + first.getId()
                    + "&role=COVER_IMAGE"));
            assertThat(anonymous.statusCode()).isIn(302, 303);
            assertThat(anonymous.headers().firstValue("location").orElse(""))
                    .contains("/login");

            var login = get(http, base.resolve("/login"));
            assertThat(login.statusCode()).isEqualTo(200);
            String loginCsrf = csrf(login.body());
            var auth = form(http, base.resolve("/login"), loginCsrf,
                    "username=" + enc(adminUsername) + "&password=" + enc(adminPassword));
            assertThat(auth.statusCode()).isEqualTo(302);

            String pickerPath = "/admin/media?revisionId=" + first.getId() + "&role=COVER_IMAGE";
            var picker = get(http, base.resolve(pickerPath));
            assertThat(picker.statusCode()).isEqualTo(200);
            String token = csrf(picker.body());

            UUID imageId = upload(http, base, first.getId(), token);
            UUID repeatId = upload(http, base, second.getId(), token);
            assertThat(repeatId).isEqualTo(imageId);
            var image = files.findById(imageId).orElseThrow();
            assertThat(image.getStatus()).isEqualTo(FileAssetStatus.READY);
            assertThat(image.getKind()).isEqualTo(FileAssetKind.COVER_IMAGE);
            assertThat(image.getSizeBytes()).isEqualTo(PNG.length);

            var preview = http.send(HttpRequest.newBuilder(
                    base.resolve("/admin/media/" + imageId + "/preview")).GET().build(),
                    HttpResponse.BodyHandlers.ofByteArray());
            assertThat(preview.statusCode()).isEqualTo(200);
            assertThat(preview.body()).isEqualTo(PNG);

            for (UUID id : List.of(first.getId(), second.getId())) {
                var bound = form(http, base.resolve("/admin/media/bind"), token,
                        "revisionId=" + enc(id.toString()) + "&role=COVER_IMAGE&assetId=" + imageId);
                assertThat(bound.statusCode()).isEqualTo(302);
                var binding = bindings.findByContentRevision_IdAndRole(id, ContentAssetRole.COVER_IMAGE)
                        .orElseThrow();
                assertThat(binding.getFileAsset().getId()).isEqualTo(imageId);
            }

            // Actual publication controller must reject an empty candidate without
            // allowing an invalid root to become CURRENT.
            var createCandidate = form(http, base.resolve("/admin/publication/candidates"), token, "");
            assertThat(createCandidate.statusCode()).isEqualTo(302);
            String candidatePath = createCandidate.headers().firstValue("location").orElseThrow();
            assertThat(candidatePath).contains("/admin/publication/candidates/");
            var candidatePage = get(http, base.resolve(candidatePath));
            assertThat(candidatePage.statusCode()).isEqualTo(200);
            var rejected = form(http, base.resolve(candidatePath + "/validate"),
                    token, "exactRefs=");
            assertThat(rejected.statusCode()).isEqualTo(302);
            var draftAfterFailure = get(http, base.resolve(candidatePath));
            assertThat(draftAfterFailure.body()).contains("DRAFT");

            var missingCsrf = http.send(HttpRequest.newBuilder(base.resolve("/admin/media/bind"))
                    .header("Content-Type", "application/x-www-form-urlencoded")
                    .POST(HttpRequest.BodyPublishers.ofString(
                            "revisionId=" + first.getId() + "&role=COVER_IMAGE&assetId=" + imageId))
                    .build(), HttpResponse.BodyHandlers.ofString());
            assertThat(missingCsrf.statusCode()).isEqualTo(403);
        }
    }

    private UUID upload(HttpClient http, URI base, UUID revisionId, String csrf) throws Exception {
        String boundary = "R5" + UUID.randomUUID().toString().replace("-", "");
        byte[] prefix = ("--" + boundary + "\r\n"
                + "Content-Disposition: form-data; name=\"revisionId\"\r\n\r\n"
                + revisionId + "\r\n--" + boundary + "\r\n"
                + "Content-Disposition: form-data; name=\"role\"\r\n\r\n"
                + "COVER_IMAGE\r\n--" + boundary + "\r\n"
                + "Content-Disposition: form-data; name=\"file\"; filename=\"sample.png\"\r\n"
                + "Content-Type: image/png\r\n\r\n").getBytes(StandardCharsets.UTF_8);
        byte[] suffix = ("\r\n--" + boundary + "--\r\n").getBytes(StandardCharsets.UTF_8);
        byte[] body = new byte[prefix.length + PNG.length + suffix.length];
        System.arraycopy(prefix, 0, body, 0, prefix.length);
        System.arraycopy(PNG, 0, body, prefix.length, PNG.length);
        System.arraycopy(suffix, 0, body, prefix.length + PNG.length, suffix.length);
        var response = http.send(HttpRequest.newBuilder(base.resolve("/admin/media/upload"))
                .header("X-CSRF-TOKEN", csrf)
                .header("Content-Type", "multipart/form-data; boundary=" + boundary)
                .POST(HttpRequest.BodyPublishers.ofByteArray(body)).build(),
                HttpResponse.BodyHandlers.ofString());
        assertThat(response.statusCode()).isEqualTo(302);
        var picker = get(http, base.resolve(response.headers().firstValue("location").orElseThrow()));
        assertThat(picker.statusCode()).isEqualTo(200);
        var match = UUID_PATTERN.matcher(picker.body());
        assertThat(match.find()).as("picker exposes uploaded image id").isTrue();
        return UUID.fromString(match.group(1));
    }

    private static HttpResponse<String> get(HttpClient http, URI uri) throws Exception {
        return http.send(HttpRequest.newBuilder(uri).GET().build(), HttpResponse.BodyHandlers.ofString());
    }

    private static HttpResponse<String> form(HttpClient http, URI uri, String token, String data)
            throws Exception {
        return http.send(HttpRequest.newBuilder(uri)
                .header("X-CSRF-TOKEN", token)
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(data)).build(),
                HttpResponse.BodyHandlers.ofString());
    }

    private static String csrf(String html) {
        var match = CSRF.matcher(html);
        assertThat(match.find()).as("CSRF token in HTML").isTrue();
        return match.group(1) == null ? match.group(2) : match.group(1);
    }

    private static String enc(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    private static PhraseContentRevisionEntity draft(String code) {
        return new PhraseContentRevisionEntity(new BusinessCode(code), new RevisionNumber(1),
                new Sha256Digest("c".repeat(64)), "R5 media test", "English",
                "Media library binding acceptance", new CatalogueCode("GENERAL"),
                new CatalogueCode("B1"), 1, List.of(new CatalogueCode("SPEAKING")),
                AvailabilityStatus.ACTIVE, "Could you introduce yourself?",
                "Professional interviews", List.of("I am a software engineer."));
    }
}
