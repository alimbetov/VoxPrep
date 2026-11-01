# CareerSpeak Flutter — ТЗ «Прослушать материал»

**Document version:** 2.0  
**Status:** IMPLEMENTATION-READY / NORMATIVE FLUTTER FEATURE CONTRACT  
**Scope:** Flutter only  
**Branch:** `feat/flutter-adversarial-hardening`  
**Backend change required:** NO, если CURRENT `ContentRevision` уже публикует exact audio asset  
**Primary goal:** дать пользователю простой, надёжный и restart-safe способ прослушать полный аудиоматериал одного текущего learning-content item без создания отдельной audio-session подсистемы.

---

## 1. Product intent

Функция решает одну задачу:

> Пользователь открыл конкретный материал и хочет прослушать его целиком, поставить на паузу, перемотать и позже продолжить с сохранённой позиции.

Нормативный UX:

```text
Content Detail
────────────────────────
Heap vs Stack
Memory management in Java

[ 🎧 Listen material ]

Read
...
────────────────────────
```

После старта:

```text
🎧 Listen material

01:12 / 03:18
━━━━━━━━●━━━━━━━━━━━━━━━

[ Pause ]
```

Это **single-content playback**:

```text
1 ContentIdentity
+ 1 exact ContentRevision
+ 1 exact published audio asset
+ 1 active playback session maximum
```

Это НЕ playlist, НЕ collection player и НЕ отдельный learning mode.

---

## 2. User stories

### US-LM-01 — Start listening

Как пользователь, я хочу нажать `Listen material` на Content Detail и начать прослушивание exact audio текущего материала.

### US-LM-02 — Pause/resume

Как пользователь, я хочу поставить воспроизведение на паузу и продолжить без потери позиции.

### US-LM-03 — Seek

Как пользователь, я хочу переместиться в другую позицию аудио через progress slider.

### US-LM-04 — Reopen/resume

Как пользователь, я хочу закрыть экран/приложение и при следующем запуске того же exact revision продолжить с последней сохранённой позиции.

### US-LM-05 — Offline playback

Как пользователь, я хочу слушать уже verified local audio без сети.

### US-LM-06 — Safe failure

Как пользователь, я хочу сохранить доступ к тексту материала, даже если audio отсутствует, повреждено, сеть недоступна или player не смог открыть файл.

---

## 3. Scope

### 3.1 MUST

1. `Listen material` доступен только для `ContentItem.hasAudio == true`.
2. Playback работает только с exact `ContentIdentity + revision`.
3. Используется существующий `AudioPlaybackController`.
4. Audio разрешается через существующий `AssetResolver`.
5. Verified local audio используется без network request.
6. Missing local audio может быть получено только через существующий Backend media path.
7. До playback remote bytes проходят size/SHA-256 verification и atomic local placement.
8. Поддерживаются:
   - Play;
   - Pause;
   - Resume;
   - Seek;
   - current position;
   - duration, когда она известна;
   - Retry после retryable failure.
9. Playback position сохраняется локально.
10. Position переживает app/repository/controller reopen.
11. Position относится только к exact revision.
12. Completed playback устанавливает `LISTENED=true`.
13. Completion сбрасывает resume position в `0`.
14. Следующий явный Play после completion начинает материал с начала.
15. `LISTENED`, `COMPLETED`, `FAVORITE` остаются независимыми markers.
16. Audio failure не меняет `COMPLETED` и `FAVORITE`.
17. Content Detail остаётся usable при audio failure.
18. UI не показывает raw exception/backend/storage data.
19. Одновременно существует максимум одна effective playback session.
20. Lifecycle/dispose не оставляет dangling subscriptions/session.

### 3.2 SHOULD

- UI должен реактивно отражать controller state;
- progress slider не должен прыгать назад из-за stale event;
- rapid double tap не должен создавать дублирующий engine session;
- Retry должен повторять полный resolve/open path текущего exact revision;
- failure copy должна быть короткой и learner-safe;
- no-audio content не должен показывать disabled декоративную кнопку — action лучше скрыть;
- playback state не должен блокировать чтение/scrolling Content Detail.

### 3.3 OUT OF SCOPE

```text
playback speed
Listen All / whole collection
playlist / queue
Continue Listening на Home
background playback
lock-screen controls
media notification controls
segment repeat
shadowing loops
A/B repeat
Audio Review
STT
pronunciation scoring
learner microphone recording
runtime mobile TTS
server-side playback progress
new Backend API
new Backend AudioSession aggregate
analytics platform
```

Ни одна из этих возможностей не должна быть скрыто добавлена в рамках LM.1–LM.6.

---

## 4. Existing architecture — mandatory reuse

Реализация обязана использовать текущую production цепочку:

```text
Content Detail UI
      ↓
AudioPlaybackController
      ↓
ResolveAudioAsset
      ↓
AssetResolver
      ↓
verified local file
      │
      └── local miss
            ↓
      AssetDownloadManager
            ↓
      Backend media API
            ↓
      verify size + SHA-256
            ↓
      atomic local placement
      ↓
AudioPlaybackEngine.openLocal(...)
      ↓
AudioPlaybackSession
```

Основные существующие компоненты:

```text
lib/application/services/audio_playback_controller.dart
lib/application/services/asset_resolver.dart
lib/application/services/asset_download_manager.dart
lib/application/ports/audio_playback_engine.dart
LearnerStateRepository
ContentMarkerState
```

### Architectural prohibition

Запрещено без отдельного архитектурного решения создавать:

```text
SecondAudioController
MaterialAudioService
AudioSessionRepository
PlaybackCubit parallel to current controller
new persistence table only for this feature
```

Если текущий controller реально не способен выполнить acceptance requirement, сначала фиксируется конкретный limitation и только потом минимально расширяется существующая abstraction.

---

## 5. Domain and identity semantics

### 5.1 Playback identity

```text
PlaybackTarget = ContentIdentity + exact contentRevision
```

`ContentIdentity` включает существующую бизнес-идентичность content item; revision обязателен.

### 5.2 Audio availability

UI eligibility:

```text
ContentItem.hasAudio == true
```

Но `hasAudio=true` означает только, что CURRENT publication заявляет наличие audio capability для материала.

Фактический playback всё равно обязан пройти:

```text
exact ref resolution
→ local integrity verification
→ optional reacquire
→ media type validation
→ engine open
```

`hasAudio=true` НЕ гарантирует, что local file уже существует.

### 5.3 Exact revision fencing

Rules:

1. Position revision `N` не используется для revision `N+1`.
2. Asset другого content/revision не используется как fallback.
3. Missing/corrupt asset не заменяется sibling audio.
4. CURRENT publication update не переписывает identity уже открытого immutable revision.
5. Если exact revision/asset больше невозможно безопасно resolve, playback fail-closed.
6. Ни UI, ни controller не должны угадывать «ближайший» revision.

---

## 6. Learner marker semantics

Существующая модель:

```text
FAVORITE
LISTENED
COMPLETED
lastPositionMs
lastRevisionSeen
```

Эти значения имеют разные смыслы.

### 6.1 FAVORITE

Пользовательская отметка/curation.

Playback не должен автоматически изменять FAVORITE.

### 6.2 COMPLETED

Завершение learning material как учебной единицы.

Audio completion НЕ должен автоматически означать `COMPLETED=true`, если текущая продуктовая логика отдельно управляет completion.

### 6.3 LISTENED

Нормативно:

```text
LISTENED = true
только после реального AudioPlaybackCompleted
для exact revision
```

Не выставлять LISTENED:

```text
на Play
на Resolve success
на openLocal success
после 5 секунд playback
после Seek near end
на Pause
при download success
```

Текущий controller уже выставляет `LISTENED=true` после playback completion; это поведение сохраняется.

### 6.4 Resume progress

```text
lastRevisionSeen
lastPositionMs
```

используются для resume exact revision.

Completion:

```text
LISTENED = true
lastRevisionSeen = exact revision
lastPositionMs = 0
```

Таким образом следующая explicit playback session стартует с начала.

---

## 7. State machine

Используется существующий `AudioPlaybackPhase`:

```text
idle
resolving
playing
paused
stopped
completed
failed
```

### 7.1 Allowed transitions

```text
idle      → resolving
stopped   → resolving
completed → resolving (restart from 0)
failed    → resolving (Retry)

resolving → playing
resolving → failed
resolving → stopped/superseded

playing   → paused
playing   → stopped
playing   → completed
playing   → failed

paused    → playing
paused    → stopped
paused    → failed
```

### 7.2 UI mapping

| Phase | Primary UI | Seek | Retry | Notes |
|---|---|---:|---:|---|
| `idle` | `Listen material` | no | no | no active session |
| `resolving` | spinner / `Preparing audio…` | no | no | duplicate start disabled |
| `playing` | `Pause` | yes | no | progress reactive |
| `paused` | `Resume` | yes | no | position persisted |
| `stopped` | `Listen material` | no active seek | no | new start may resume persisted position |
| `completed` | `Play again` | optional visual end state | no | next Play starts at 0 |
| `failed` | safe error | no | if retryable | Content Detail still usable |

### 7.3 Concurrency rule

There is exactly one controller-owned active session.

```text
A resolving
user starts B
→ generation increments
→ late A resolve/open/event ignored
→ only B may mutate current state
```

---

## 8. Content Detail UX specification

### 8.1 Placement

Audio block располагается после title/subtitle/metadata и до основного body, если это не конфликтует с уже существующей Content Detail composition.

Recommended:

```text
Heap vs Stack
Memory management in Java
VOCABULARY · B2 · 6 min

┌─────────────────────────────┐
│ 🎧 Listen material          │
│                             │
│ 01:12                03:18  │
│ ━━━━━━━━━●━━━━━━━━━━━━━━━   │
│                             │
│          [ Pause ]          │
└─────────────────────────────┘

Read
...
```

### 8.2 No audio

If:

```text
ContentItem.hasAudio == false
```

то audio block/action не показывается.

Не показывать постоянно disabled control с текстом `Audio unavailable`, если audio не является частью этого content type/revision.

### 8.3 Resolving

Display:

```text
Preparing audio…
```

Primary action disabled while current exact target resolves.

Content text remains scrollable/usable.

### 8.4 Playing

Display:

```text
Pause
current position
known duration
seek slider
```

Slider value bounded:

```text
0 <= position <= duration
```

If duration temporarily unknown, UI must not render NaN/Infinity/negative values.

### 8.5 Paused

Display same progress plus `Resume`.

### 8.6 Completed

Display:

```text
Listened
[ Play again ]
```

Do not visually imply that the learning item is necessarily `COMPLETED`.

### 8.7 Failed

Example safe copies:

Offline/local missing:

```text
Audio is not available offline yet.
```

Generic retryable:

```text
Audio could not be loaded. Please try again.
```

Non-retryable exact asset failure:

```text
Audio is unavailable for this material.
```

UI must not render `ApplicationFailure.message` blindly if that message may originate from infrastructure.

---

## 9. Time/progress formatting

Display format:

```text
m:ss
```

For >= 1 hour:

```text
h:mm:ss
```

Rules:

- negative values clamp to zero;
- position greater than known duration clamps to duration;
- unknown duration renders placeholder or only current position;
- no `NaN`, `Infinity`, `null`, `-0:01` in UI.

---

## 10. Seek semantics

### 10.1 User action

Slider/tap results in:

```text
controller.seek(targetMs)
```

### 10.2 Persistence

Successful seek attempts to persist new position immediately through existing controller behavior.

### 10.3 Seek failure

If engine seek fails:

- state becomes safe failure according to controller contract;
- UI does not pretend seek succeeded;
- learner state is not corrupted;
- text content stays available.

### 10.4 Seek to end

Seeking close to/at duration by itself MUST NOT set `LISTENED=true`.

Only actual `AudioPlaybackCompleted` owns LISTENED transition.

---

## 11. Persistence and restart semantics

### 11.1 Authoritative data

MVP persists playback progress in existing learner state:

```text
lastRevisionSeen
lastPositionMs
```

No new playback-progress table unless current repository cannot persist these fields correctly.

### 11.2 Save triggers

Progress may be saved:

```text
periodically while position advances
on Pause
on explicit Seek
on Stop
on controller dispose / screen leave
```

Current controller interval policy remains authoritative.

### 11.3 Write ordering

Progress writes must remain serialized so an older delayed write cannot overwrite a newer position.

### 11.4 Persistence failure

Persistence failure:

```text
must not crash player/UI
must not fabricate LISTENED
must not delete FAVORITE/COMPLETED
may surface safe non-blocking failure state
```

### 11.5 Reopen acceptance

Given:

```text
revision = 7
saved position = 92_000 ms
```

After new repository/controller/app composition:

```text
open same ContentIdentity revision 7
→ Play
→ engine seeks to 92_000 ms
→ playback continues
```

For revision 8:

```text
→ starts at 0
```

---

## 12. Asset resolution and offline behavior

### 12.1 Verified local path

```text
Listen
→ AssetResolver
→ verified local exact asset
→ AudioPlaybackEngine.openLocal
→ Play
```

Network must not be required.

### 12.2 Missing local asset, online

```text
Listen
→ local miss
→ existing authenticated Backend media delivery
→ bounded download
→ size verify
→ SHA-256 verify
→ atomic final placement
→ openLocal
→ Play
```

### 12.3 Missing local asset, offline

```text
Listen
→ local miss
→ remote acquisition unavailable
→ safe retryable failure
```

Do not delete learner progress.

### 12.4 Corrupt local asset

```text
corrupt local copy
→ must not open/play
→ reject/delete via existing AssetFileStore policy
→ reacquire if possible
→ otherwise safe failure
```

### 12.5 MIME/media type

Resolved asset must have:

```text
mediaType startsWith "audio/"
```

otherwise fail closed with `ASSET_NOT_AUDIO` semantics.

---

## 13. Authentication boundary

Content Detail/player never owns token logic.

Existing installation auth flow remains:

```text
request
→ 401
→ centralized single-flight re-registration/rotation
→ bounded replay once where supported
→ second rejection fail closed
```

Player UI must not:

```text
read installation token
write Authorization header
register installation
rotate token
create new installationId
```

---

## 14. Navigation and lifecycle

### 14.1 Leave Content Detail

Required:

```text
persist current position where applicable
→ stop session
→ cancel event subscription
→ dispose session
```

No background playback in this slice.

### 14.2 App lifecycle

If current architecture tears down controller/session when app/widget composition is disposed, progress must be persisted before disposal completes.

No requirement is introduced to keep audio alive while app is backgrounded.

### 14.3 Switch content

```text
A playing/resolving
→ navigate/start B
→ A closes/supersedes
→ B becomes sole current target
```

### 14.4 Idempotent dispose

Repeated `dispose()`/cleanup must not throw or create duplicate writes/sessions.

---

## 15. Failure and retry matrix

| Failure | Expected behavior | Retry | Learner state |
|---|---|---:|---|
| verified local file exists | play | n/a | normal |
| offline + local missing | safe message | yes | preserve |
| timeout / network failure | safe message | yes | preserve |
| HTTP 429/5xx | safe message | yes | preserve |
| 401 | centralized auth recovery | bounded | preserve |
| repeated 401 | fail closed | no auto-loop | preserve |
| 403 | unavailable | no blind retry | preserve |
| 404 exact asset | unavailable | no fallback | preserve |
| 409 asset not ready | safe retryable | yes | preserve |
| checksum mismatch | do not play | reacquire if policy permits | preserve |
| size mismatch | do not play | reacquire if policy permits | preserve |
| non-audio MIME | fail closed | no | preserve |
| engine open failure | safe message | optional Retry | preserve |
| engine play failure | safe message | optional Retry | preserve |
| seek failure | safe failure | user Retry/restart | preserve prior valid state |
| progress DB write failure | no crash | later action may retry | do not alter markers incorrectly |

---

## 16. Learner-safe error policy

Forbidden in visible UI:

```text
exception.toString()
ApplicationFailure.details dump
HTTP response body
SQL/Drift exception
filesystem path
asset local path
token
Authorization header
RustFS endpoint/bucket/key
stack trace
```

Safe UI messages are owned by presentation mapping, not copied blindly from infrastructure exceptions.

Retry button appears only when retry has meaningful semantics.

---

## 17. Accessibility

Minimum semantic labels:

```text
Listen material
Play audio
Pause audio
Resume audio
Audio progress
Audio position
Audio duration
Retry audio
Play again
```

Requirements:

- minimum practical touch target around Flutter Material accessibility defaults;
- controls usable without color-only meaning;
- progress semantics expose meaningful value where possible;
- loading state announced without trapping focus;
- dynamic failure should be perceivable to screen readers;
- text content remains accessible while audio is resolving/failed.

---

## 18. Performance/NFR

### 18.1 UI

- position events must not cause whole-app rebuilds;
- rebuild only player/content-detail subtree required for state;
- no file hash/download work in widget `build()`;
- no DB calls directly from widget `build()`.

### 18.2 Playback

- local verified file should open without unnecessary network call;
- duplicate taps must not create duplicate downloads or sessions where existing dedupe/controller semantics prevent it;
- progress persistence interval must remain bounded, not every audio frame/event.

### 18.3 Storage

Playback completion/progress does not pin asset forever.

Asset cache eviction remains independent from:

```text
FAVORITE
LISTENED
COMPLETED
Review state
PracticeTest history
```

Deleting cached audio must never delete learner state.

---

## 19. Privacy/security

This feature records only local playback state already modeled by the application.

Do not add:

```text
microphone permission
contacts/location permission
advertising identifier
hardware identity
server learner profile
new analytics payload containing content history
```

No new permission should be required for foreground local-file playback.

---

## 20. Backend contract

No backend expansion is required.

Existing media route remains:

```http
GET /api/v1/media/assets/{assetId}/content
Authorization: Bearer <installationToken>
```

Backend owns:

```text
exact published audio asset reference
assetId
mediaType
byte size
SHA-256 checksum
publication eligibility
authenticated byte streaming
```

Flutter owns:

```text
resolution
download
verification
local cache
playback
position persistence
LISTENED marker transition
UI state
```

If a content revision lacks a valid published audio asset, backend/UI must not fabricate one.

---

## 21. Implementation slices

Реализовать в указанном порядке.

### LM.1 — Content Detail integration

Scope:

- locate current Content Detail implementation;
- expose audio block only when `item.hasAudio`;
- obtain current `ContentMarkerState`;
- bind exact item/revision to existing `AudioPlaybackController`;
- no new player architecture.

Acceptance:

```text
content hasAudio=false → no Listen action
content hasAudio=true  → Listen action visible
Tap Listen → controller.play(exact item, learner state)
```

### LM.2 — Reactive player presentation

Scope:

- bind controller stream/provider to player UI;
- implement idle/resolving/playing/paused/completed/failed mapping;
- current position + duration formatting;
- seek slider;
- safe Retry.

Acceptance:

```text
Play → resolving → playing
Pause → paused
Resume → playing
Completion → completed + Play again
Failure → safe message (+ Retry only when appropriate)
```

### LM.3 — Marker/progress semantics

Scope:

- preserve FAVORITE/COMPLETED independence;
- LISTENED only on actual completion;
- exact revision resume;
- completion resets position to zero.

Acceptance:

```text
partial listen → LISTENED remains false
full playback completion → LISTENED true
seek-to-end without completion event → LISTENED false
completion does not set COMPLETED
favorite unchanged
```

### LM.4 — Restart/reopen qualification

Prove:

```text
play revision 7
→ progress saved
→ dispose/reopen repository/controller/app
→ revision 7 resumes
→ revision 8 starts from 0
```

Also prove completion/reopen restarts from zero.

### LM.5 — Offline/integrity qualification

Prove:

```text
verified local + offline → play success
local missing + online → download/verify/play
local missing + offline → safe failure
corrupt local + online → reject/reacquire/play
corrupt local + offline → safe failure
checksum mismatch → never play bytes
size mismatch → never play bytes
non-audio MIME → fail closed
```

### LM.6 — Lifecycle/concurrency adversarial

Prove:

```text
rapid Play ×2 → one effective session
A resolving → B starts → late A ignored
leave screen while playing → persisted + disposed
leave while resolving → late result ignored
Pause DB-write failure → no crash / no marker corruption
Seek failure → safe failure
engine open failure → safe failure
engine play failure → safe failure
repeated dispose → safe
```

### LM.7 — UI/accessibility qualification

Prove:

- semantics labels exist;
- no-audio block hidden;
- resolving disables duplicate action;
- failure copy contains no raw infrastructure text;
- text material remains usable during audio failure;
- no overflow at narrow mobile width;
- unknown duration does not break progress UI.

### LM.8 — Exact-SHA qualification

Required on one exact SHA:

```text
dart format --set-exit-if-changed .
flutter analyze
focused controller/audio tests
focused Content Detail widget tests
restart/offline/adversarial acceptance
full flutter test
```

Feature is not declared CLOSED until all required checks are green on the same SHA.

---

## 22. Required test matrix

### 22.1 Controller/application tests

Must cover:

```text
play exact target
resume paused current session
duplicate play is idempotent
resume same exact revision
stale revision starts at 0
seek clamps to valid range
seek persists position
pause persists position
stop persists position
completion sets LISTENED
completion resets position
completion does not set COMPLETED
completion does not mutate FAVORITE
non-audio asset fails closed
resolver failure
engine open failure
engine play failure
superseded resolve ignored
superseded open disposed/ignored
late event generation ignored
progress writes preserve ordering
dispose persists and closes resources
```

### 22.2 Widget tests

Must cover:

```text
hasAudio=false hides audio UI
idle shows Listen material
resolving shows progress and blocks duplicate start
playing shows Pause
paused shows Resume
position/duration renders correctly
unknown duration renders safely
seek invokes controller
completed shows Play again/Listened state
failed shows safe copy
retry invokes current exact target again
raw failure details not rendered
```

### 22.3 Acceptance tests

Must cover:

```text
verified audio offline playback
missing local audio online acquisition
missing local audio offline degradation
corrupt asset recovery/failure
restart/reopen resume
exact revision fencing
completed reopen starts at 0
navigation disposal
rapid interaction concurrency
learner markers survive cache eviction
```

---

## 23. Acceptance scenarios (Given / When / Then)

### AC-01 — Local playback

**Given** exact audio already verified locally  
**When** learner taps `Listen material`  
**Then** audio plays without network dependency.

### AC-02 — Resume

**Given** revision 4 has saved position 61 seconds  
**When** learner reopens revision 4 and starts playback  
**Then** session seeks to 61 seconds before playback.

### AC-03 — Revision isolation

**Given** revision 4 saved position 61 seconds  
**When** CURRENT content is revision 5  
**Then** revision 5 starts at zero.

### AC-04 — Completion

**Given** playback reaches natural completion event  
**When** controller processes completion  
**Then** `LISTENED=true`, resume position becomes zero, FAVORITE/COMPLETED remain unchanged.

### AC-05 — Seek is not completion

**Given** content is not listened  
**When** learner seeks to the final position  
**Then** LISTENED remains false until actual completion event.

### AC-06 — Offline missing

**Given** audio is not cached and network is unavailable  
**When** learner taps Listen  
**Then** safe offline message is shown and textual content remains usable.

### AC-07 — Corrupt bytes

**Given** local file fails expected checksum  
**When** playback resolves asset  
**Then** corrupt bytes are never passed to engine.

### AC-08 — Double tap

**Given** exact target is resolving  
**When** learner taps Listen repeatedly  
**Then** no parallel effective playback sessions are created.

### AC-09 — Supersession

**Given** content A is resolving  
**When** learner starts content B before A completes  
**Then** late A result cannot replace B state.

### AC-10 — Leave screen

**Given** audio is playing at a non-zero position  
**When** Content Detail/controller is disposed  
**Then** position is persisted and playback resources are closed.

### AC-11 — Persistence failure

**Given** playback progress write fails  
**When** Pause/Seek/Dispose triggers persistence  
**Then** app does not crash and FAVORITE/LISTENED/COMPLETED are not incorrectly changed.

### AC-12 — Safe error UI

**Given** infrastructure returns an internal failure containing technical details  
**When** player enters failed state  
**Then** UI renders only learner-safe copy.

---

## 24. Definition of Done

Feature is accepted only when all statements are true:

```text
[ ] Listen material is visible only for content with audio capability
[ ] existing AudioPlaybackController is reused
[ ] existing AssetResolver/download/integrity path is reused
[ ] only exact ContentIdentity + revision can play
[ ] Play works
[ ] Pause works
[ ] Resume works
[ ] Seek works
[ ] current position is visible
[ ] duration is visible when known
[ ] unknown duration is safe
[ ] partial playback persists position
[ ] same exact revision resumes after reopen
[ ] new revision never inherits old position
[ ] LISTENED is set only on actual completion
[ ] completion resets resume position to 0
[ ] LISTENED does not imply COMPLETED
[ ] FAVORITE is unaffected
[ ] verified local audio works offline
[ ] missing/corrupt audio fails safely
[ ] corrupt/unverified bytes never reach engine
[ ] Content Detail text stays usable on audio failure
[ ] auth logic remains outside UI/player
[ ] no raw errors/secrets/storage paths reach UI
[ ] no parallel/dangling sessions
[ ] late superseded events cannot corrupt current state
[ ] accessibility semantics are qualified
[ ] focused tests GREEN
[ ] restart/offline/adversarial tests GREEN
[ ] flutter analyze GREEN
[ ] full flutter test GREEN on same exact SHA
```

---

## 25. Explicit future extension points

Current design must not block, but does not implement:

```text
playback speed
segment repeat
shadowing loop
collection Listen All
playlist/queue
background playback
lock-screen controls
Continue Listening
Audio Review
```

Future features should extend `AudioPlaybackEngine` / existing controller boundary rather than fork playback architecture.

---

## 26. Final invariants

```text
ContentRevision owns exact published audio reference.
ContentItem.hasAudio controls learner-facing audio affordance.
AssetResolver owns exact local/remote resolution.
AssetDownloadManager owns bounded acquisition.
Integrity layer owns size/SHA-256 verification.
AudioPlaybackController owns one playback session and progress semantics.
AudioPlaybackEngine owns platform playback mechanics.
LearnerStateRepository owns durable local playback state/markers.
LISTENED means actual completed listening, not merely playback started.
COMPLETED remains a separate learning marker.
FAVORITE remains a separate curation marker.
Backend owns published bytes and authenticated delivery only.
```

The feature remains intentionally narrow: **make one current learning material listenable, resumable, exact-revision-safe and offline-safe without creating a second audio subsystem.**
