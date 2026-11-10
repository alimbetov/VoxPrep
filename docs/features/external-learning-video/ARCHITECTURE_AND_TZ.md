# External learning video V1 — additive media, not an image replacement

Status: **V1 implementation in Draft PR #56; automated/device acceptance pending**
Baseline: `main` @ `2b5deffa5cfa94d3a24cfe3212a90f2542345ecc`
Branch: `feat/content-external-learning-video-v1`


## Implementation delta — PR #56

The code in this branch now implements draft-only video references and a frozen
one-row-per-revision copy, captured by a PostgreSQL trigger on the
\`content_revision.published_at\` transition. This copy is immutable and
rolled back atomically if the content publication transaction fails.

The **versioned learner projection** is a separate, installation-authenticated
\`GET /api/v2/content/{contentType}/{contentCode}/external-video\`, guarded by
the existing FREE/FULL content policy. It returns HTTP 204 when no video is
published. The response includes \`schemaVersion=1\`, exact content
identity/revision, CURRENT \`contentVersion\` and \`rootSha256\`, and a
canonical YouTube URL derived from its video ID.

**Important compatibility limitation:** the video is **not a member of the
existing schema-2 pack/root canonical-hash calculation**. The returned CURRENT
root identity scopes the reference, while immutable DB snapshot triggers
prevent later changes; the root digest itself does not cryptographically
commit to this separate extension. Treat SHA-covered vNext manifest inclusion
as a separate contract-versioning gate if required for the public release.
Never claim old root hashes authenticate the video URL.

Flutter fetches the optional v2 reference only online through authenticated
\`ApiClient\` and adds a user-gesture external-launch button. The link is
not yet stored in Drift. This intentionally leaves the existing offline
content/image/audio behavior unchanged. Offline video metadata persistence
requires a separately versioned, atomic CURRENT extension and new tests;
do not silently add new keys to strict legacy decoders.

Implemented tests: Java URL adversarial cases, installation route protection,
PostgreSQL draft-to-published video snapshot and Flutter strict v2 response
decoder. Browser admin form, actual phone external launch, offline-video
metadata and canonical root extension remain independent acceptance gates.

## Decision

A learner may have **cover image, content image, existing MP3, AND an optional external educational video link** attached to the *same exact content revision*. None replaces another. A video link is never interpreted as a binary FileAsset, stored in RustFS, placed into the audio-role policy, or downloaded automatically. In Flutter it appears as a distinct action, **«Смотреть учебное видео»**, while the original image and TTS controls remain visible.

V1 supports one curated external video per exact ContentRevision for the five normal learner lessons: Vocabulary, Phrase, Interview, Topic and Shadowing. Question and Practice Test are deliberately excluded because they are delivered by a distinct assessment API. Multiple videos, embedded video playback, full video uploads and lesson-specific video timeline synchronization are out of scope.

## Existing production surfaces verified

- `MediaLibraryService` / `MediaLibraryMvcController`: only READY PNG/JPEG/WebP files backed by RustFS; `ContentAssetRole.COVER_IMAGE` and `CONTENT_IMAGE` remain unchanged.
- `ContentAssetBindingService`: exact revision + role + immutable-on-published asset bindings; requires a real `FileAsset` with a matching image/audio kind. Do **not** add a fake file kind, zero-byte placeholder or URL to this relation.
- `ContentRevisionSnapshot`: typed text/body with immutable approved/published revision identity.
- `LearnerExactContentPayloadService.ExactPayload` and Flutter `ContentPayloadDecoder`: strict exact-key wire decoding. A new top-level property on existing wire payloads **will be rejected** by old app builds.
- `JpaPublicationWireSnapshotWriter`: freezes immutable exact CURRENT publication packs and canonical hashes. A video link must be part of frozen publication, not a live join against mutable editor state.
- `ContentDetailPanel`: existing image/audio flow remains untouched; a video action must not set `hasAudio`, synthesize TTS, or replace image widgets.

## Proposed domain and persistence boundary

Create `ContentExternalVideo` / `ContentExternalVideoRepository` under the existing backend asset/media domain, but model it as a **curated external reference, not a FileAsset**.

Minimal migration (exact schema conventions to be aligned with migration inventory):
- `app.content_external_video`: `id UUID PRIMARY KEY`, `content_revision_id UUID NOT NULL UNIQUE REFERENCES app.content_revision(id)`, `provider VARCHAR NOT NULL`, `provider_video_id VARCHAR NOT NULL`, `title VARCHAR NOT NULL`, `language_tag VARCHAR NULL`, `created_at`, `updated_at` and `created_by` as appropriate to existing admin auditing.
- Store provider + canonical ID, **not an arbitrary mutable full URL**; canonical watch URL is derived by backend/client from a fixed provider implementation.
- Current V1 provider: YouTube standard video ID (11 chars of URL-safe alphanumeric, hyphen, underscore). Short videos using the same stable YouTube video ID may be allowed. V1 excludes Shorts playlist/time/query params and other providers until separately reviewed.
- One link per draft revision; removal is permitted only before publication. Editing an approved/immutable version should follow the existing new-draft revision workflow; **published rows cannot be mutated or deleted**.
- Validate optional title length (1–160), provider+ID, and BCP-47 language tag; audit all updates.
- There is **no global uniqueness** on `provider_video_id`: the same public video can be referenced by multiple lessons. A matching link on two revisions is not duplicated binary storage.
- Do not query YouTube oEmbed/thumbnail APIs from the backend in V1. Manual title, optional license/attribution and trusted provider URL avoid SSRF and extra API dependencies. Display only editorially approved resources; external copyright/license and availability remain the editor's responsibility.

## Content Studio / Media Library

Add an additive **External learning video** section to the existing revision editor alongside the image picker and TTS preview:
- Current cover/content image selectors remain independently editable.
- New fields: YouTube URL, human-readable video title, optional language/attribution; a small preview of the validated canonical destination; Save/Remove controls for editable drafts.
- Show an external-link icon and provider; never pretend a remote link is a READY RustFS image.
- If no video exists, no new required field or validation warning is shown.
- On approved/published revisions, show frozen metadata read-only.
- Keep CSRF, admin authentication, validation and audit rules identical to other authoring routes.
- Reject attempts to edit or attach to published revisions, including direct POST bypass.

## Publication and Flutter contract

**Compatibility rule:** current `ContentPayloadDecoder` rejects unknown top-level fields. Do not silently extend existing v1/v2 payloads or mutate a published pack. Choose a controlled, backwards-compatible boundary:

Recommended v1 rollout:
1. Keep existing canonical content payload, text, images, media manifests and TTS unchanged.
2. During publication freeze, include optional video metadata in a **versioned extension** with exact release/content identity and SHA-covered snapshot. A new Flutter decoder or versioned `/v2` projection will explicitly validate it; old clients keep their old contract. Architect must choose the concrete versioned wire location after reviewing `PublicationWireDocumentKind` and manifest schema; never assert an unsupported field is already accepted.
3. On Flutter, expose an immutable `ExternalLearningVideo?` associated with exact `ContentIdentity + revision + rootSha256`, persisted atomically in Drift with CURRENT. If V1 chooses a separately requested publication-scoped endpoint, its response must be frozen to an exact CURRENT root; the client must not fetch authoring state or cache a latest URL under an older publication.
4. The UI shows cover/content image and the existing audio player exactly as before, then a separate CTA **«Смотреть учебное видео»**. Use external browser/OS handler through the normal Flutter URL-launch adapter after explicit tap. Do not silently open an embedded WebView or autoplay.
5. Display a clear external-service warning, require network, and show a useful offline/unavailable state; **video is not an offline asset** and must not be included in required asset prefetch or checksum-based binary cache.
6. FREE/FULL content authorization is checked before exposing the publication-scoped video metadata. Direct URL discovery outside the app cannot itself be made private if the YouTube video is public; do not claim DRM or provider-side access enforcement.
7. Strict downgrade: old apps ignore the extension **only through explicitly compatible versioning**, not by loosening the existing strict payload parser globally.

Proposed illustrative metadata (not yet committed as a wire schema):

```json
{
  "kind": "EXTERNAL_VIDEO",
  "provider": "YOUTUBE",
  "providerVideoId": "dQw4w9WgXcQ",
  "title": "Example educational video",
  "languageTag": "en-US"
}
```

The example video ID is a placeholder to explain structure; no educational suitability is implied.

The current implementation also rejects video references on Question and Practice Test at both service and PostgreSQL trigger levels. The Content Studio video section is hidden for these assessment-only types.

## Security / privacy

- Accept only `https://www.youtube.com/watch?v=...`, `https://youtube.com/watch?v=...`, `https://youtu.be/...` and other explicitly enumerated YouTube canonical variants; extract and validate exactly one video ID. Reject deceptive hosts (`youtube.com.evil.example`), userinfo, `javascript:`, HTTP, credentials, fragments and unexpected query parameters; never send backend HTTP requests to user-entered addresses.
- Validate encoded/Unicode hosts carefully and normalize only an explicit hostname allowlist. Disallow arbitrary redirects as a backend URL validation mechanism.
- Render title as escaped plain text; do not inject URL/title as trusted HTML or JavaScript.
- Only Admin can author/edit references. Review/audit editorial decisions. Do not expose drafts in learner API.
- Explicitly state opening an external service may send IP/device information to the provider under its own privacy practices; no remote tracking pixels or thumbnail fetch in background.
- External availability, region restrictions, private videos, ads and takedowns are not under VoxPrep control. Never fail otherwise valid content publishing because a remote video becomes unreachable later.

## Acceptance conditions

A1. Existing image upload/list/bind/preview works unchanged, including image + TTS on the same revision.
A2. Draft revision can independently set/remove a YouTube video without removing either image.
A3. Invalid URL, wrong host/scheme, duplicate query, unsupported provider and script injection fail closed.
A4. Published revision/video remains immutable; new draft changes do not alter old frozen root.
A5. Frozen publication and Flutter agree on exact video metadata/root SHA even after restart.
A6. Old Flutter release parses its previous strict contract unchanged and remains usable.
A7. New Flutter shows **both** image and optional video button, not one replacing the other.
A8. Video opens only by explicit user action in supported external viewer; offline shows no falsely playable media.
A9. Missing video does not create a button, media download or warning; content remains usable.
A10. FULL video metadata is not leaked through FREE-only endpoint.
A11. Android+iOS device smoke and accessibility test for button, state and external navigation.
A12. Existing TTS, RustFS, Content Studio approval/publication and R1 A1 tests remain green on exact SHA.

## Delivery slices

- **V1.0 Design / Test-First (this branch):** approved contract/versions, adversarial scenarios and test skeletons. No production migrations/code.
- **V1.1 Backend:** versioned migration, admin service+MVC, validation, audit, publication-scoped projection and backend tests.
- **V1.2 Flutter:** parser/store extension under explicit versioning, additive button and user-gesture navigation adapter, widget + Drift tests.
- **V1.3 Real acceptance:** Content Studio browser authoring → release N/N+1 → Flutter Android/iOS + image/audio/video verification; migration, security and rollback review.

Feature flag defaults OFF until new app clients are capable of receiving the versioned link. A missing or disabled external video never blocks text, image, TTS, review or publication.

## Explicit non-goals

No video file upload, RustFS streaming, transcoding, YouTube API crawling, embedded playback, automatic thumbnail fetching, generic URL launcher, arbitrary websites, LMS analytics, captions or automatic transcript extraction. Re-evaluate separately when evidence of real learner demand exists.
