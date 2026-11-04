package io.github.alimbetov.voxprep.backend.learner;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.alimbetov.voxprep.backend.publication.domain.PublicationExactContentRef;
import java.net.CookieManager;
import java.net.CookiePolicy;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;
import java.util.UUID;
import java.util.regex.Pattern;

/** Test-only browser client; real servlet HTTP, session cookie, Thymeleaf CSRF, PostgreSQL. */
final class R5AdminHttpPublicationWorkflow {
    private static final Pattern VERSION = Pattern.compile(
            "name=\\\"expectedVersion\\\"[^>]*value=\\\"([0-9]+)\\\"");
    private static final Pattern CSRF = Pattern.compile(
            "name=\"_csrf\"[^>]*value=\"([^\"]+)\"|name=\"_csrf\"[^>]*content=\"([^\"]+)\"");
    private final URI base;
    private final String username;
    private final String password;

    R5AdminHttpPublicationWorkflow(int port, String username, String password) {
        this.base = URI.create("http://127.0.0.1:" + port);
        this.username = username;
        this.password = password;
    }

    UUID createPhrase(String code, String title, String phrase) throws Exception {
        CookieManager cookies = new CookieManager(null, CookiePolicy.ACCEPT_ALL);
        try (HttpClient http = HttpClient.newBuilder().cookieHandler(cookies)
                .connectTimeout(Duration.ofSeconds(5))
                .followRedirects(HttpClient.Redirect.NEVER).build()) {
            var login = get(http, "/login");
            assertThat(login.statusCode()).isEqualTo(200);
            var auth = post(http, "/login", csrf(login.body()),
                    "username=" + enc(username) + "&password=" + enc(password));
            assertThat(auth.statusCode()).isEqualTo(302);
            var page = get(http, "/admin/content/revisions/new");
            assertThat(page.statusCode()).isEqualTo(200);
            assertThat(page.body()).contains("Create first content revision");
            String payload = "contentCode=" + enc(code)
                    + "&expectedVersion=0&bodyType=phrase"
                    + "&title=" + enc(title)
                    + "&subtitle=CareerSpeak&description=Live+HTTP+created+content"
                    + "&categoryCode=GENERAL&levelCode=B1&minutes=2"
                    + "&skillCodes=SPEAKING&availability=ACTIVE"
                    + "&phrase=" + enc(phrase)
                    + "&usage=Interview+preparation&examples=" + enc(phrase + " Example.");
            var created = post(http, "/admin/content/revisions", csrf(page.body()), payload);
            assertThat(created.statusCode()).as("create first revision POST").isEqualTo(302);
            String location = created.headers().firstValue("location").orElseThrow();
            assertThat(location).matches("/admin/content/revisions/[0-9a-f-]{36}/edit");
            UUID id = UUID.fromString(location.split("/")[4]);
            assertThat(get(http, location).body()).contains(code).contains("DRAFT");
            return id;
        }
    }

    void bindAndPublish(UUID revisionId, UUID assetId, UUID candidateId,
            List<PublicationExactContentRef> refs) throws Exception {
        CookieManager cookies = new CookieManager(null, CookiePolicy.ACCEPT_ALL);
        try (HttpClient http = HttpClient.newBuilder().cookieHandler(cookies)
                .connectTimeout(Duration.ofSeconds(5))
                .followRedirects(HttpClient.Redirect.NEVER).build()) {
            HttpResponse<String> login = get(http, "/login");
            assertThat(login.statusCode()).isEqualTo(200);
            HttpResponse<String> auth = post(http, "/login", csrf(login.body()),
                    "username=" + enc(username) + "&password=" + enc(password));
            assertThat(auth.statusCode()).isEqualTo(302);
            HttpResponse<String> picker = get(http,
                    "/admin/media?revisionId=" + revisionId + "&role=COVER_IMAGE");
            assertThat(picker.statusCode()).isEqualTo(200);
            String token = csrf(picker.body());
            HttpResponse<String> bind = post(http, "/admin/media/bind", token,
                    "revisionId=" + revisionId + "&role=COVER_IMAGE&assetId=" + assetId);
            assertThat(bind.statusCode()).isEqualTo(302);
            assertThat(bind.headers().firstValue("location").orElse(""))
                    .contains("/admin/content/revisions/" + revisionId + "/edit");

            // Prove actual Content Studio lifecycle DRAFT → READY_FOR_AUDIO
            // → READY_FOR_REVIEW → APPROVED before publication.
            String editPath = "/admin/content/revisions/" + revisionId + "/edit";
            for (String step : List.of("ready-for-audio", "review", "approve")) {
                var edit = get(http, editPath);
                assertThat(edit.statusCode()).isEqualTo(200);
                var version = VERSION.matcher(edit.body());
                assertThat(version.find()).as("expectedVersion exists in lifecycle form").isTrue();
                String payload = "expectedVersion=" + enc(version.group(1))
                        + "&reason=R5_ACCEPTANCE&comment=Live+HTTP+workflow";
                var change = post(http,
                        "/admin/content/revisions/" + revisionId + "/" + step, token, payload);
                assertThat(change.statusCode()).as(step).isEqualTo(302);
            }
            assertThat(get(http, editPath).body()).contains("APPROVED");

            StringBuilder lines = new StringBuilder();
            for (var ref : refs) {
                if (!lines.isEmpty()) lines.append('\n');
                lines.append(ref.identity().contentCode().value()).append('|')
                        .append(ref.identity().contentType().wireName()).append('|')
                        .append(ref.identity().revisionNumber().value()).append('|')
                        .append(ref.checksum().value());
            }
            String route = "/admin/publication/candidates/" + candidateId;
            HttpResponse<String> candidate = get(http, route);
            assertThat(candidate.statusCode()).isEqualTo(200);
            HttpResponse<String> validated = post(http, route + "/validate", token,
                    "exactRefs=" + enc(lines.toString()));
            assertThat(validated.statusCode()).isEqualTo(302);
            HttpResponse<String> frozen = get(http, route);
            assertThat(frozen.statusCode()).isEqualTo(200);
            assertThat(frozen.body()).contains("VALIDATED");
            assertThat(frozen.body()).contains("Frozen exact references");

            HttpResponse<String> published = post(http, route + "/publish", token, "");
            assertThat(published.statusCode()).isEqualTo(302);
            assertThat(published.headers().firstValue("location").orElse(""))
                    .contains("/admin/publication");
            HttpResponse<String> index = get(http, "/admin/publication");
            assertThat(index.statusCode()).isEqualTo(200);
            assertThat(index.body()).contains("Current learner release");
        }
    }

    private HttpResponse<String> get(HttpClient http, String path) throws Exception {
        return http.send(HttpRequest.newBuilder(base.resolve(path)).GET().build(),
                HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> post(HttpClient http, String path, String token, String data)
            throws Exception {
        return http.send(HttpRequest.newBuilder(base.resolve(path))
                .header("X-CSRF-TOKEN", token)
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(data)).build(),
                HttpResponse.BodyHandlers.ofString());
    }

    private static String csrf(String html) {
        var match = CSRF.matcher(html);
        assertThat(match.find()).as("CSRF token supplied by real Spring Security page").isTrue();
        return match.group(1) == null ? match.group(2) : match.group(1);
    }

    private static String enc(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }
}
