# CareerSpeak Flutter — ТЗ «Прослушать материал»

**Status:** READY FOR IMPLEMENTATION  
**Scope:** Flutter only  
**Branch:** `feat/flutter-adversarial-hardening`  
**Backend change required:** NO, если `ContentRevision` уже содержит опубликованный audio asset  
**Primary goal:** дать пользователю возможность прослушать полный аудиоматериал текущей карточки/урока без создания отдельной audio-session подсистемы.

---

## 1. Product goal

На экране Content Detail пользователь должен иметь простой режим:

```text
Content Detail
────────────────────────
Heap vs Stack

[ Read ]
[ 🎧 Listen material ]
────────────────────────
```

После запуска пользователь может:

```text
Play / Pause
Seek
Resume from saved position
Stop / leave screen safely
```

Это прослушивание **одного exact ContentRevision**, а не playlist, collection player или отдельный learning mode.

---

## 2. MVP scope

### MUST

1. Кнопка `Listen material` показывается только если CURRENT `ContentRevision` имеет доступный audio asset.
2. Нажатие запускает существующий production audio path.
3. Audio asset разрешается через `AssetResolver`.
4. Если verified local file существует — воспроизведение начинается из локального файла.
5. Если файла нет — разрешён существующий Backend media download path с size/SHA-256 verification и atomic local placement.
6. Поддерживаются:
   - Play;
   - Pause;
   - Seek;
   - отображение current position;
   - отображение duration, когда она известна;
   - resume с последней сохранённой позиции для exact revision.
7. Позиция сохраняется локально и переживает restart/reopen.
8. Завершённый материал при следующем явном запуске начинается с `0`.
9. Ошибка audio/download не ломает Content Detail и не удаляет learner state.
10. UI не показывает raw exception/backend text.

### SHOULD

- прогресс воспроизведения обновляется реактивно;
- Pause визуально сохраняет текущую позицию;
- при переключении на другой Content текущая session корректно закрывается;
- повторное нажатие Play для уже активного content не создаёт вторую параллельную session;
- UI корректно работает offline, если exact audio уже verified locally.

### OUT OF SCOPE

```text
play whole collection
playlist
Continue Listening на Home
background playback
lock-screen controls
speed control
segment repeat
shadowing loops
STT / pronunciation scoring
learner audio recording
runtime mobile TTS
server-side playback progress
new backend AudioSession aggregate
```

Эти функции могут быть отдельными будущими slices и не должны усложнять текущую реализацию.

---

## 3. Existing architecture to reuse

Реализация MUST использовать уже существующие production components:

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
      └── if missing → AssetDownloadManager / Backend media API
      ↓
AudioPlaybackEngine
      ↓
local audio playback
```

Existing components:

```text
lib/application/services/audio_playback_controller.dart
lib/application/services/asset_resolver.dart
lib/application/services/asset_download_manager.dart
lib/application/ports/audio_playback_engine.dart
LearnerStateRepository
```

Do NOT create another parallel player controller unless a proven limitation requires it.

---

## 4. Exact revision semantics

Playback identity is:

```text
ContentIdentity
+ exact contentRevision
```

Rules:

1. progress of revision `N` MUST NOT be resumed for revision `N+1`;
2. audio resolved for another revision MUST NOT be used;
3. if CURRENT changes while an old content page is open, playback must continue only for the exact already-opened immutable revision or fail closed according to existing asset/publication semantics;
4. corrupt/dangling audio reference must never silently fall back to a sibling/other asset.

---

## 5. Playback state

Reuse `ContentPlaybackState` and `AudioPlaybackPhase`.

Expected UI mapping:

```text
idle        → Listen material
resolving   → loading indicator / disabled duplicate start
playing     → Pause button + active progress
paused      → Play/Resume button + progress
stopped     → Play
completed   → completed state; next explicit Play starts at 0
failed      → safe error + Retry
```

No additional state machine should be introduced unless required by acceptance tests.

---

## 6. Progress persistence

Existing learner-state progress is authoritative for MVP.

Persist at least:

```text
lastRevisionSeen
lastPositionMs
```

Rules:

- progress belongs to exact `ContentRevision`;
- periodic persistence may use the existing controller interval;
- Pause must attempt to persist current position;
- leaving/closing current session must persist current position where existing controller policy permits;
- completion must use existing completion semantics and must not leave a stale resume point at the end;
- persistence failure must not crash UI.

No backend synchronization of playback progress in MVP.

---

## 7. Content Detail UX

Recommended compact layout:

```text
Heap vs Stack
Memory management in Java

┌─────────────────────────────┐
│ 🎧 Listen material          │
│                             │
│        01:12 / 03:18        │
│ ━━━━━━━━━●━━━━━━━━━━━━━━━   │
│                             │
│          [ Pause ]          │
└─────────────────────────────┘

Read
...
```

### Controls

Minimum controls:

```text
Play / Pause
Seek slider
current position
known duration
Retry on failure
```

No speed selector in this slice because current `AudioPlaybackSession` contract does not expose playback-rate control.

### Accessibility

Controls MUST have semantic labels suitable for screen readers:

```text
Listen material
Play audio
Pause audio
Audio progress
Retry audio
```

Touch targets should follow normal Flutter accessibility sizing.

---

## 8. Asset availability behavior

### Verified local audio

```text
Listen
→ AssetResolver
→ local verified audio found
→ openLocal
→ play
```

Must work with no network.

### Missing local audio

```text
Listen
→ AssetResolver
→ local miss
→ existing download path
→ Backend authenticated media API
→ size verification
→ SHA-256 verification
→ atomic local placement
→ openLocal
→ play
```

### Corrupt local audio

Corrupt copy MUST NOT play.

Existing verification/repair policy remains authoritative:

```text
corrupt local copy
→ reject/delete according to AssetFileStore policy
→ reacquire if network available
→ otherwise safe failure
```

---

## 9. Failure behavior

Learner-safe cases:

### Offline + local audio exists

```text
PLAY SUCCESS
```

### Offline + local audio missing

```text
show:
"Audio is not available offline yet."

Content text remains usable.
```

### Download / timeout / 5xx

```text
show safe retryable message
[ Retry ]
```

### 401

Existing installation-auth recovery owns token rotation/retry. Content UI must not implement token logic.

### Asset not found / not ready / invalid

Fail closed. Do not play another asset and do not invent fallback audio.

### Engine/openLocal failure

Show safe audio unavailable state; Content Detail remains usable.

Raw fields forbidden in learner UI:

```text
exception.toString()
HTTP body
SQL/storage exception
filesystem path
token
RustFS/storage information
```

---

## 10. Navigation/lifecycle behavior

When user leaves Content Detail:

```text
persist current position
→ stop/dispose current playback session
```

Required:

- no dangling stream subscriptions;
- no playback from two content details simultaneously;
- no second engine session after rapid double tap;
- disposal is idempotent;
- late events from superseded generation do not mutate the new content state.

The existing generation/supersession logic in `AudioPlaybackController` should remain the concurrency boundary.

---

## 11. No backend contract expansion

This feature MUST NOT require a new learner API if current publication already supplies an audio `ManifestAssetDescriptor` for the exact content revision.

Existing path remains:

```http
GET /api/v1/media/assets/{assetId}/content
Authorization: Bearer <installationToken>
```

Backend responsibilities remain:

```text
published exact audio asset metadata
assetId
mediaType
size/checksum metadata
authenticated byte streaming
```

Flutter responsibilities remain:

```text
resolve/download/verify/cache/play
playback progress
resume position
UI state
```

---

## 12. Implementation slices

Implement in this exact order.

### LM.1 — Content Detail integration

- locate current Content Detail audio presentation;
- add `Listen material` affordance;
- bind exact `ContentItem` + learner marker state;
- do not add new player architecture.

**Acceptance:** content with audio can initiate `AudioPlaybackController.play()`.

### LM.2 — Reactive player UI

Bind `ContentPlaybackState` to UI:

```text
resolving
playing
paused
completed
failed
```

Expose Play/Pause, position, duration, seek and Retry.

### LM.3 — Resume/reopen qualification

Prove:

```text
play → seek/progress → pause/leave
→ recreate app/repository/controller
→ reopen same exact revision
→ play resumes from saved position
```

Also prove a different revision starts from `0`.

### LM.4 — Offline/asset qualification

Prove:

```text
verified local + offline → plays
missing local + offline → safe failure
corrupt local → never plays corrupt bytes
missing local + network → download/verify/play
```

### LM.5 — Lifecycle/concurrency adversarial

Prove:

```text
rapid Play x2 → one effective session
A resolving → user starts B → A late result ignored
leave screen while playing → session disposed
pause persistence failure → no crash
engine open failure → safe failure
```

### LM.6 — Exact-SHA qualification

Required on the same exact SHA:

```text
dart format --set-exit-if-changed
flutter analyze
focused audio/player tests
full flutter test
```

No `Listen material DONE` declaration before same-SHA GREEN.

---

## 13. Required tests

Minimum new/updated tests:

### Controller/application

- resume same exact revision;
- do not resume stale revision;
- completed content restarts at zero;
- duplicate play does not create parallel session;
- superseded resolve/open does not overwrite current state;
- Pause persists progress;
- resolver failure maps to failed state;
- non-audio asset fails closed.

### Widget

- content without audio does not expose active Listen action;
- content with audio exposes Listen;
- resolving state disables duplicate start;
- Play → Pause UI transition;
- progress/duration rendering;
- seek invokes controller;
- failure shows safe copy and Retry;
- raw failure message is not rendered.

### Acceptance

- verified audio plays offline;
- progress survives repository/app reopen;
- corrupt/missing audio behavior;
- exact revision fencing.

---

## 14. Definition of Done

Feature is accepted only when all are true:

```text
[ ] Listen material exists on Content Detail when audio is available
[ ] playback uses existing AudioPlaybackController
[ ] playback uses AssetResolver / verified local file path
[ ] Play/Pause works
[ ] Seek works
[ ] position/duration are visible
[ ] saved position resumes after reopen for same exact revision
[ ] new revision never inherits stale position
[ ] verified local audio works offline
[ ] missing/corrupt audio fails safely
[ ] Content Detail remains usable on audio failure
[ ] no raw errors/secrets/storage paths reach UI
[ ] no parallel/dangling audio sessions
[ ] focused adversarial tests GREEN
[ ] flutter analyze GREEN
[ ] full flutter test GREEN on same exact SHA
```

---

## 15. Explicit future extensions

Not part of this implementation, but this design must not block future additions:

```text
playback speed
segment repeat
collection Listen All
background playback
lock-screen controls
Continue Listening
Audio Review
Shadowing-specific player
```

Future features should extend the existing playback abstraction rather than fork it.

---

## 16. Final architectural invariant

```text
ContentRevision owns exact published audio reference.
AssetResolver owns local/remote asset resolution.
AudioPlaybackController owns one playback session and progress semantics.
AudioPlaybackEngine owns platform playback mechanics.
Flutter owns playback progress locally.
Backend owns published audio bytes and authenticated delivery.
```

The feature is deliberately small: **make current learning material listenable, resumable and offline-safe without creating another subsystem.**
