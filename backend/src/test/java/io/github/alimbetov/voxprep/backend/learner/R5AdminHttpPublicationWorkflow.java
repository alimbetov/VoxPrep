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
        return createContent(code, title, "phrase",
                "&phrase=" + enc(phrase) + "&usage=Interview+preparation&examples="
                        + enc(phrase + " Example."));
    }

    UUID createQuestion(String code) throws Exception {
        return createContent(code, "Dependency injection", "question",
                "&questionText=" + enc("What is dependency injection?")
                        + "&explanation=" + enc("Decoupling construction from use.")
                        + "&options=" + enc("A|true|Pass dependencies through a constructor\n"
                                + "B|false|Use global mutable state"));
    }

    UUID createPracticeTest(String code, UUID questionId) throws Exception {
        return createContent(code, "Backend basics", "practice_test",
                "&instructions=" + enc("Choose one option")
                        + "&passingScorePercent=80&questionRevisionIds=" + questionId);
    }

    private UUID createContent(String code, String title, String bodyType,
            String typedBodyFields) throws Exception {
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
                    + "&expectedVersion=0&bodyType=" + enc(bodyType)
                    + "&title=" + enc(title)
                    + "&subtitle=CareerSpeak&description=Live+HTTP+created+content"
                    + "&categoryCode=GENERAL&levelCode=B1&minutes=2"
                    + "&skillCodes=SPEAKING&availability=ACTIVE"
                    + typedBodyFields;
            var created = post(http, "/admin/content/revisions", csrf(page.body()), payload);
            assertThat(created.statusCode()).as("create first revision POST").isEqualTo(302);
            String location = created.headers().firstValue("location").orElseThrow();
            String createdPath = base.resolve(location).getPath();
            assertThat(createdPath).matches("/admin/content/revisions/[0-9a-f-]{36}/edit");
            UUID id = UUID.fromString(createdPath.split("/")[4]);
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

    UUID createCatalogue(UUID iconAssetId) throws Exception {
        CookieManager cookies = new CookieManager(null, CookiePolicy.ACCEPT_ALL);
        try (HttpClient http = HttpClient.newBuilder().cookieHandler(cookies)
                .connectTimeout(Duration.ofSeconds(5))
                .followRedirects(HttpClient.Redirect.NEVER).build()) {
            var login = get(http, "/login");
            assertThat(login.statusCode()).isEqualTo(200);
            assertThat(post(http, "/login", csrf(login.body()),
                    "username=" + enc(username) + "&password=" + enc(password)).statusCode())
                    .isEqualTo(302);
            String token = csrf(get(http, "/admin/catalogue/verticals/new").body());
            var vertical = post(http, "/admin/catalogue/verticals", token,
                    "expectedVersion=0&code=A1_CAREER&sectionCode=A1_TECH"
                            + "&title=Career+English&description=Technical+interviews"
                            + "&iconAssetId=" + iconAssetId
                            + "&sortOrder=0&availability=ACTIVE");
            assertThat(vertical.statusCode()).isEqualTo(302);
            UUID verticalId = queryId(vertical, "verticalId");
            var goal = post(http, "/admin/catalogue/goals", token,
                    "expectedVersion=0&code=A1_INTERVIEW&verticalId=" + verticalId
                            + "&title=Interview+skills&description=Prepare+for+interviews"
                            + "&sortOrder=0&availability=ACTIVE");
            assertThat(goal.statusCode()).isEqualTo(302);
            UUID goalId = queryId(goal, "goalId");
            var track = post(http, "/admin/catalogue/tracks", token,
                    "expectedVersion=0&code=A1_JAVA&goalId=" + goalId
                            + "&title=Java+developer&description=Technical+English"
                            + "&levelCode=B1&sortOrder=0&availability=ACTIVE");
            assertThat(track.statusCode()).isEqualTo(302);
            UUID trackId = queryId(track, "trackId");
            for (String code : List.of("A1_FREE", "A1_FULL")) {
                var collection = post(http, "/admin/catalogue/collections", token,
                        "expectedVersion=0&code=" + code + "&trackId=" + trackId
                                + "&title=" + (code.equals("A1_FREE") ? "Start+here" : "Advanced")
                                + "&description=" + (code.equals("A1_FREE") ? "First+free+block" : "Premium+block")
                                + "&accessLevel=" + (code.equals("A1_FREE") ? "FREE" : "FULL")
                                + "&sortOrder=" + (code.equals("A1_FREE") ? 0 : 1)
                                + "&availability=ACTIVE");
                assertThat(collection.statusCode()).as(code).isEqualTo(302);
            }
            var page = get(http, "/admin/catalogue?trackId=" + trackId);
            assertThat(page.statusCode()).isEqualTo(200);
            assertThat(page.body()).contains("A1_FREE").contains("A1_FULL");
            return trackId;
        }
    }

    UUID appendMember(UUID collectionId, UUID revisionId) throws Exception {
        CookieManager cookies = new CookieManager(null, CookiePolicy.ACCEPT_ALL);
        try (HttpClient http = HttpClient.newBuilder().cookieHandler(cookies)
                .connectTimeout(Duration.ofSeconds(5))
                .followRedirects(HttpClient.Redirect.NEVER).build()) {
            var login = get(http, "/login");
            assertThat(post(http, "/login", csrf(login.body()),
                    "username=" + enc(username) + "&password=" + enc(password)).statusCode())
                    .isEqualTo(302);
            String path = "/admin/catalogue/collections/" + collectionId + "/members";
            var page = get(http, path);
            assertThat(page.statusCode()).isEqualTo(200);
            var appended = post(http, path, csrf(page.body()), "revisionId=" + revisionId);
            assertThat(appended.statusCode()).isEqualTo(302);
            var refreshed = get(http, path);
            assertThat(refreshed.statusCode()).isEqualTo(200);
            assertThat(refreshed.body()).contains("revision 1");
            var id = java.util.regex.Pattern.compile(
                    "/members/([0-9a-f-]{36})/replace")
                    .matcher(refreshed.body());
            // The returned UUID identifies the persisted membership, not the revision.
            assertThat(id.find()).isTrue();
            return UUID.fromString(id.group(1));
        }
    }

    UUID createCandidate() throws Exception {
        CookieManager cookies = new CookieManager(null, CookiePolicy.ACCEPT_ALL);
        try (HttpClient http = HttpClient.newBuilder().cookieHandler(cookies)
                .connectTimeout(Duration.ofSeconds(5))
                .followRedirects(HttpClient.Redirect.NEVER).build()) {
            var login = get(http, "/login");
            assertThat(post(http, "/login", csrf(login.body()),
                    "username=" + enc(username) + "&password=" + enc(password)).statusCode())
                    .isEqualTo(302);
            var page = get(http, "/admin/publication");
            var created = post(http, "/admin/publication/candidates", csrf(page.body()), "");
            assertThat(created.statusCode()).isEqualTo(302);
            var path = base.resolve(created.headers().firstValue("location").orElseThrow()).getPath();
            assertThat(path).matches("/admin/publication/candidates/[0-9a-f-]{36}");
            return UUID.fromString(path.substring(path.lastIndexOf('/') + 1));
        }
    }

    private UUID queryId(HttpResponse<String> response, String name) {
        var uri = base.resolve(response.headers().firstValue("location").orElseThrow());
        var match = java.util.regex.Pattern.compile("(?:^|&)" + name
                + "=([0-9a-f-]{36})(?:&|$)").matcher(uri.getRawQuery());
        assertThat(match.find()).as(name + " included in catalogue redirect").isTrue();
        return UUID.fromString(match.group(1));
    }

    void approveDraft(UUID revisionId) throws Exception {
        CookieManager cookies = new CookieManager(null, CookiePolicy.ACCEPT_ALL);
        try (HttpClient http = HttpClient.newBuilder().cookieHandler(cookies)
                .connectTimeout(Duration.ofSeconds(5))
                .followRedirects(HttpClient.Redirect.NEVER).build()) {
            var login = get(http, "/login");
            assertThat(login.statusCode()).isEqualTo(200);
            assertThat(post(http, "/login", csrf(login.body()),
                    "username=" + enc(username) + "&password=" + enc(password)).statusCode())
                    .isEqualTo(302);
            String editPath = "/admin/content/revisions/" + revisionId + "/edit";
            var initial = get(http, editPath);
            assertThat(initial.statusCode()).isEqualTo(200);
            String token = csrf(initial.body());
            for (String step : List.of("ready-for-audio", "review", "approve")) {
                var edit = get(http, editPath);
                assertThat(edit.statusCode()).isEqualTo(200);
                var response = post(http, "/admin/content/revisions/" + revisionId + "/" + step,
                        token, "expectedVersion=" + version(edit.body())
                                + "&reason=R5_AUTHORING&comment=Real+HTTP+review");
                assertThat(response.statusCode()).as(step).isEqualTo(302);
            }
            assertThat(get(http, editPath).body()).contains("APPROVED");
        }
    }

    UUID reviseAndPublish(UUID previousRevisionId, UUID assetId, UUID collectionId,
            UUID oldMemberId, List<PublicationExactContentRef> oldRefs,
            java.util.function.Function<UUID, PublicationExactContentRef> revisedRef)
            throws Exception {
        CookieManager cookies = new CookieManager(null, CookiePolicy.ACCEPT_ALL);
        try (HttpClient http = HttpClient.newBuilder().cookieHandler(cookies)
                .connectTimeout(Duration.ofSeconds(5))
                .followRedirects(HttpClient.Redirect.NEVER).build()) {
            var login = get(http, "/login");
            assertThat(login.statusCode()).isEqualTo(200);
            assertThat(post(http, "/login", csrf(login.body()),
                    "username=" + enc(username) + "&password=" + enc(password)).statusCode()).isEqualTo(302);
            String oldEdit = "/admin/content/revisions/" + previousRevisionId + "/edit";
            var oldPage = get(http, oldEdit);
            assertThat(oldPage.statusCode()).isEqualTo(200);
            String token = csrf(oldPage.body());
            var created = post(http, "/admin/content/revisions/" + previousRevisionId + "/next", token,
                    "expectedVersion=" + version(oldPage.body()));
            assertThat(created.statusCode()).isEqualTo(302);
            String editPath = base.resolve(created.headers().firstValue("location").orElseThrow()).getPath();
            assertThat(editPath).matches("/admin/content/revisions/[0-9a-f-]{36}/edit");
            UUID revisedId = UUID.fromString(editPath.split("/")[4]);

            // Editing the *new* DRAFT must change both checksum and actual learner text.
            var page = get(http, editPath);
            assertThat(page.statusCode()).isEqualTo(200);
            String payload = "expectedVersion=" + version(page.body())
                    + "&bodyType=phrase&title=" + enc("Interview introduction v2")
                    + "&subtitle=CareerSpeak&description=Revised+learning+content"
                    + "&categoryCode=GENERAL&levelCode=B1&minutes=2"
                    + "&skillCodes=SPEAKING&availability=ACTIVE"
                    + "&phrase=" + enc("Could you introduce yourself professionally?")
                    + "&usage=Updated+interview+preparation"
                    + "&examples=" + enc("I can introduce myself professionally.");
            var updated = post(http, "/admin/content/revisions/" + revisedId, token, payload);
            assertThat(updated.statusCode()).isEqualTo(302);
            var bound = post(http, "/admin/media/bind", token,
                    "revisionId=" + revisedId + "&role=COVER_IMAGE&assetId=" + assetId);
            assertThat(bound.statusCode()).isEqualTo(302);

            for (String step : List.of("ready-for-audio", "review", "approve")) {
                var edit = get(http, editPath);
                assertThat(edit.statusCode()).isEqualTo(200);
                var response = post(http, "/admin/content/revisions/" + revisedId + "/" + step,
                        token, "expectedVersion=" + version(edit.body())
                                + "&reason=R5_N2&comment=HTTP+publication+upgrade");
                assertThat(response.statusCode()).as(step).isEqualTo(302);
            }
            assertThat(get(http, editPath).body()).contains("APPROVED");

            // Replace the collection slot via production MVC, never mutate frozen N.
            var memberPage = get(http, "/admin/catalogue/collections/" + collectionId + "/members");
            assertThat(memberPage.statusCode()).isEqualTo(200);
            var replaced = post(http, "/admin/catalogue/collections/" + collectionId
                    + "/members/" + oldMemberId + "/replace", token, "newRevisionId=" + revisedId);
            assertThat(replaced.statusCode()).isEqualTo(302);

            PublicationExactContentRef next = revisedRef.apply(revisedId);
            assertThat(next.identity().revisionNumber().value()).isEqualTo(2);
            List<PublicationExactContentRef> refs = oldRefs.stream()
                    .map(ref -> ref.identity().contentCode().equals(next.identity().contentCode())
                            && ref.identity().contentType() == next.identity().contentType()
                            ? next : ref)
                    .toList();
            var draft = post(http, "/admin/publication/candidates", token, "");
            assertThat(draft.statusCode()).isEqualTo(302);
            String candidatePath = draft.headers().firstValue("location").orElseThrow();
            StringBuilder lines = new StringBuilder();
            for (var ref : refs) {
                if (!lines.isEmpty()) lines.append('\n');
                lines.append(ref.identity().contentCode().value()).append('|')
                        .append(ref.identity().contentType().wireName()).append('|')
                        .append(ref.identity().revisionNumber().value()).append('|')
                        .append(ref.checksum().value());
            }
            var validated = post(http, candidatePath + "/validate", token,
                    "exactRefs=" + enc(lines.toString()));
            assertThat(validated.statusCode()).isEqualTo(302);
            var frozen = get(http, candidatePath);
            assertThat(frozen.statusCode()).isEqualTo(200);
            assertThat(frozen.body()).contains("VALIDATED");
            var published = post(http, candidatePath + "/publish", token, "");
            assertThat(published.statusCode()).isEqualTo(302);
            assertThat(get(http, "/admin/publication").body()).contains("Current learner release");
            return revisedId;
        }
    }

    private static String version(String html) {
        var match = VERSION.matcher(html);
        assertThat(match.find()).as("expectedVersion field").isTrue();
        return match.group(1);
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
