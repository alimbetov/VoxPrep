# External Learning Video V1 — scenario-driven acceptance and implementation backlog

Status: **TEST DESIGN / NOT EXECUTED**
Source: [ARCHITECTURE_AND_TZ.md](ARCHITECTURE_AND_TZ.md)
Invariant: **additional to** `coverImage`, `contentImage`, existing role-aware TTS audio. Never replace, remove or degrade those resources.

## Test-first acceptance matrix

| ID | Layer | Preconditions / action | Required result |
| --- | --- | --- | --- |
| EV-01 | Admin MVC | Edit draft with cover image, content image and audio; attach canonical YouTube URL | All existing bindings persist; link attached to exact revision |
| EV-02 | Admin MVC | Remove only video on draft | Image and audio links unchanged |
| EV-03 | Admin MVC | Create content without any video | Existing behavior unchanged; no UI button/warning |
| EV-04 | Admin MVC | Try POST on published revision | 409/appropriate domain error; DB and frozen wire unchanged |
| EV-05 | Admin MVC | Unauthorized user or missing CSRF attempts update | Rejected, audit invariant preserved |
| EV-06 | URL validator | Standard `www.youtube.com/watch?v=<id>` | Canonical YOUTUBE + 11-char ID |
| EV-07 | URL validator | `youtu.be/<id>` | Same canonical YOUTUBE + ID |
| EV-08 | URL validator | `youtube.com.evil.example` or userinfo credentials | Rejected |
| EV-09 | URL validator | `javascript:`, `file:`, `http:`, private host | Rejected |
| EV-10 | URL validator | Playlist-only, non-11-char ID, multiple `v` params, fragment | Rejected without network access |
| EV-11 | URL validator | URL with encoded host ambiguity, mixed case or unicode confusables | Explicit allowlist or rejected; no SSRF |
| EV-12 | Input | HTML/script in title, overlong title, bad language | Rejected or safely escaped (never executed) |
| EV-13 | Concurrency | Concurrent saves to same draft/revision | One deterministic state, optimistic/row lock, no lost update |
| EV-14 | Publication | Publish root N with image + TTS + video | All coexist, immutable root and frozen video reference |
| EV-15 | Publication | Edit video in next draft, publish N+1 | Root N unchanged; new root has new link |
| EV-16 | Publication | Failed N+1 publication (invalid cross-ref) | Old CURRENT N remains active; no partial link leak |
| EV-17 | Publication | Draft link exists but content not CURRENT | Learner API does not reveal draft link |
| EV-18 | Authorization | FULL content viewed with FREE entitlement | Video metadata not exposed; same entitlement as content |
| EV-19 | HTTP contract | Existing old-version Flutter receives old payload | Strict `ContentPayloadDecoder` still accepts unchanged payload |
| EV-20 | HTTP contract | New-version Flutter receives well-formed immutable video extension | Exact key/type/provider/id and root identity validated |
| EV-21 | HTTP contract | Unknown provider or malformed provider ID | Fail closed for unsupported extension; do not corrupt old CURRENT |
| EV-22 | Drift | Sync root N with video, close process, reopen offline | Immutable link metadata preserved, no link network request |
| EV-23 | Drift | Failed/corrupted sync N+1 | CURRENT N and its video metadata preserved |
| EV-24 | Flutter UI | Lesson with cover/content image, audio and video | Both images and audio controls remain; separate video button visible |
| EV-25 | Flutter UI | Lesson with image/audio only | Identical old UI; no placeholder video action |
| EV-26 | Flutter UI | Tap video with internet | Explicit launcher invocation for validated provider canonical link |
| EV-27 | Flutter UI | Tap video offline/no handler | Non-crashing informative UX; lesson and audio remain usable |
| EV-28 | Flutter UI | Tap video in FREE/FULL flows | No bypass of gated content or unauthorized metadata |
| EV-29 | Flutter UI | Screen reader and large font / compact viewport | Accessible label, no overflow or image suppression |
| EV-30 | Device | Android+iOS app background/return after external launch | Current lesson, scroll, playback state and progress remain consistent |
| EV-31 | Security | Remote YouTube video removed/private/blocked | App offers graceful external failure; publication remains valid |
| EV-32 | Regression | Re-run B1, A1, Flutter Main, media binding, Piper/Kokoro tests | Exact-SHA PASS; no modified image/audio semantics |

## Suggested test-first files (create during implementation)

Backend:
- `ExternalVideoUrlParserTest`: provider allowlist, canonicalization, malicious URL matrix.
- `ExternalLearningVideoServiceIntegrationTest`: Postgres persistence, optimistic/concurrent writes, draft-only update and audit.
- `ExternalLearningVideoMvcSecurityTest`: CSRF/Admin, safe escaping, role isolation.
- `ExternalVideoPublicationFreezeIntegrationTest`: exact root N/N+1, replay, authorization and fail-closed candidate.
- `ExternalVideoWireCompatibilityTest`: previous wire canonical hash stable and vNext extension deterministic.
- `ExternalVideoMediaRegressionTest`: images, TTS and video coexist without mutation.

Flutter:
- `external_learning_video_decoder_test.dart`: strict versioned schema and malicious metadata.
- `external_video_drift_offline_reopen_test.dart`: exact CURRENT/identity and N → N+1 failure rollback.
- `content_detail_external_video_test.dart`: image+TTS+video coexist and no-video unchanged.
- `external_video_launcher_test.dart`: only explicit user tap, approved HTTPS provider links, offline/error UX.
- `external_video_accessibility_test.dart`: localizations, text scaling, semantics.

## Architecture decisions to lock before backend implementation

**DEC-01:** Only links, not video binaries. Default YES.
**DEC-02:** One external video per exact content revision. Default YES.
**DEC-03:** Provider whitelist YouTube only in MVP, canonical video ID stored. Default YES.
**DEC-04:** No embedded WebView. Open externally after user tap. Default YES.
**DEC-05:** Frozen media reference bound to exact published revision, never mutable latest. Required.
**DEC-06:** Wire change must be versioned because current Flutter decoder rejects unknown keys. Required.
**DEC-07:** Video availability not guaranteed and not part of offline-required assets. Required.
**DEC-08:** Video can coexist with both existing images and all TTS roles. Required.
**DEC-09:** Video-only lessons do not bypass existing content field validation. Required.
**DEC-10:** Optional editorial attribution/license text and language metadata. Default YES.

## Done criteria

An individual scenario can be marked PASS only with test result, exact SHA and run/evidence link. Product acceptance additionally requires real Content Studio browser submission and real Flutter device external-launch check. None of the 32 scenarios is claimed executed by the creation of this document.

## Minimal implementation sequence

1. Confirm versioned publication extension shape and old-client compatibility with exact wire schemas.
2. Write red tests for URL normalization, admin auth, immutability and atomic publication.
3. Add a small relational URL-reference entity and Liquibase migration, without touching FileAsset kinds.
4. Implement admin section in existing revision editor, keeping photo controls.
5. Freeze video metadata into versioned publication projection and add it to Flutter CURRENT atomically.
6. Add one optional Flutter button after image and audio controls.
7. Run exact-SHA backend and Flutter CI plus real browser/device acceptance.
