# CareerSpeak — Learner Content State & Markers

**Document version:** 1.0  
**Status:** Normative mobile learner-state contract  
**Applies to:** CareerSpeak v0.9+  
**Target:** Flutter / Drift / Material Design 3

---

## 1. Decision

CareerSpeak SHALL expose three independent learner-facing markers where relevant:

```text
LISTENED
COMPLETED
FAVORITE
```

They have different meanings and SHALL NOT be collapsed into one generic progress flag.

```text
LISTENED
= learner has completed playback according to the feature audio policy

COMPLETED
= learner has completed the learning unit according to the feature completion policy

FAVORITE
= learner explicitly saved the content as a favorite
```

A content item may simultaneously be:

```text
LISTENED + COMPLETED + FAVORITE
```

or any other valid combination.

---

## 2. Ownership

These markers are **local durable learner state** in MVP.

They are owned by Flutter/Drift and are not backend publication state.

They SHALL survive:

```text
application restart
metadata refresh
content cache eviction
audio-file eviction
offline-pack replacement
normal manifest synchronization
```

They SHALL NOT be deleted merely because re-downloadable content/media is removed.

If content is tombstoned/inactivated by Backend, the durable marker may remain historically stored by stable content identity even though the item is no longer visible in the current learner catalog.

---

## 3. Stable identity

Learner markers reference:

```text
content_code
content_type
```

They do not depend on server numeric IDs or one cached content revision.

Example:

```text
content_code = INTERVIEW_JAVA_DI_001
content_type = INTERVIEW_QUESTION
```

If revision 3 is replaced by revision 4 under the same stable business identity, the learner marker remains associated with the logical content item unless a feature-specific migration rule explicitly says otherwise.

---

## 4. Generic Drift state

Introduce a generic durable table:

```text
content_learning_state
────────────────────────────────────────
content_code          TEXT NOT NULL
content_type          TEXT NOT NULL
listened_at           DATETIME NULL
listen_count          INTEGER NOT NULL DEFAULT 0
last_played_at        DATETIME NULL
last_position_ms      INTEGER NULL
completed_at          DATETIME NULL
completion_source     TEXT NULL
last_revision_seen    INTEGER NULL
updated_at            DATETIME NOT NULL

PK (content_code, content_type)
```

Derivation:

```text
isListened  = listened_at IS NOT NULL
isCompleted = completed_at IS NOT NULL
```

Do not persist redundant boolean fields when timestamp presence already provides the state.

`favorite` remains a separate durable table because it represents explicit user curation rather than learning progress:

```text
favorite
────────────────────────────────────────
content_code          TEXT NOT NULL
content_type          TEXT NOT NULL
created_at            DATETIME NOT NULL

PK (content_code, content_type)
```

---

## 5. Why Favorite is separate

Favorite is independent from progress.

Examples:

```text
FAVORITE + NOT_LISTENED + NOT_COMPLETED
LISTENED + FAVORITE + NOT_COMPLETED
COMPLETED + FAVORITE
COMPLETED + NOT_FAVORITE
```

A favorite SHALL NOT automatically:

```text
mark content completed
mark audio listened
pin media offline
prevent normal audio-cache eviction
```

Offline pin/download is a separate storage-retention concept.

---

## 6. LISTENED semantics

`LISTENED` is an audio-consumption marker.

Baseline rule:

```text
AudioPlaybackController reports qualified playback completion
→ content_learning_state.listened_at = now
→ listen_count += 1
```

For MVP, qualified playback completion SHOULD be based on actual playback reaching the end/completion event rather than merely opening the screen.

Seeking directly to the final position SHOULD NOT automatically count as fully listened unless the audio adapter can prove the configured playback-completion policy was satisfied.

Exact threshold/coverage rules may be feature-policy configuration and SHALL NOT be duplicated inside UI widgets.

For short word/example audio, one completed playback is sufficient.

---

## 7. Playback progress

For long-form audio, the state MAY persist:

```text
last_played_at
last_position_ms
```

This allows Resume/Continue Learning without treating partial playback as `LISTENED`.

Conceptually:

```text
started audio
→ last_position_ms updated periodically/at lifecycle boundaries

playback finished
→ listened_at set
→ last_position_ms may reset or remain as history according to feature policy
```

Do not update Drift on every audio frame; persist at bounded intervals and important lifecycle boundaries.

---

## 8. COMPLETED semantics

`COMPLETED` means the pedagogical unit is finished, not merely opened.

Completion is decided by a feature policy/application controller.

Examples:

```text
TOPIC
→ required sections completed or explicit Mark complete action

SHADOWING
→ qualified session/segments completed or explicit completion policy

INTERVIEW QUESTION
→ feature flow reaches completion according to agreed policy

PRACTICE TEST
→ attempt submitted/completed

VOCABULARY
→ vocabulary-specific progress/review policy; generic COMPLETED may be omitted where "known/review" is more meaningful
```

UI widgets SHALL NOT decide completion by themselves.

---

## 9. Completion source

Recommended values:

```text
USER_ACTION
AUTO_FLOW
TEST_SUBMIT
REVIEW_POLICY
```

`completion_source` helps diagnose and evolve completion rules without changing the visible marker semantics.

---

## 10. Manual controls

Where product UX permits, a learner MAY explicitly:

```text
Mark completed
Mark not completed
Add to favorites
Remove from favorites
```

`LISTENED` is normally automatic from playback completion, but a future explicit reset may be supported from item actions/history management.

Manual reset of `COMPLETED` clears `completed_at`/`completion_source`; it SHALL NOT delete test attempts, review history or other independent learner records.

---

## 11. Material Design 3 markers

Markers SHALL use Material 3 semantics and more than color alone.

Recommended visual language:

```text
FAVORITE
→ favorite / favorite_border icon
→ optional tooltip/semantic label

LISTENED
→ headphones/check or equivalent semantic icon
→ optional tonal status chip: "Listened"

COMPLETED
→ check_circle or equivalent semantic icon
→ optional tonal status chip: "Completed"
```

Do not use three unrelated custom icon families.

Do not encode status using only green/blue color.

---

## 12. Compact list presentation

A compact catalog row/card SHOULD remain readable and avoid badge overload.

Example:

```text
Dependency Injection                 ♥
Senior Java · Spring
✓ Completed   🎧 Listened
```

Material implementation should use actual Material icons/chips rather than emoji; the diagram is conceptual.

When horizontal space is constrained:

```text
favorite → trailing icon
completed/listened → compact icons/status line
```

When text scale is large, markers may wrap to a second line rather than clip.

---

## 13. Detail presentation

Detail screens MAY show richer status actions:

```text
[♡ Favorite]
[✓ Completed]
[🎧 Listened]
```

Conceptually these map to Material components such as:

```text
IconButton
FilterChip / AssistChip
FilledButton.tonal / OutlinedButton where an explicit state-changing action is needed
```

The exact component depends on whether the status is informational or actionable.

---

## 14. Marker precedence / visual density

The states are logically independent, but presentation MAY reduce redundant visual noise.

Example:

```text
if COMPLETED implies LISTENED for a specific feature policy
→ compact list may emphasize COMPLETED and FAVORITE
→ detail/status screen can still expose LISTENED history
```

This is a presentation optimization only; the underlying state is not merged.

---

## 15. Catalog filtering

Catalog/search screens SHOULD support learner-state filters where useful:

```text
Favorites
Listened
Not listened
Completed
Not completed
```

Filters combine with domain filters such as:

```text
CEFR
profession
seniority
skill
category
```

Example:

```text
Interview
[Senior] [Spring] [Not completed] [Favorites]
```

Filter state is local UI/query state and SHALL query Drift efficiently.

---

## 16. Sorting and Continue Learning

Learner state may drive local presentation:

```text
Continue Learning
→ recently opened, not completed first

Review incomplete
→ NOT_COMPLETED

Recently listened
→ last_played_at DESC

Favorites
→ favorite.created_at DESC
```

Backend does not need learner-history tracking for these views.

---

## 17. Required indexes

Qualify Drift indexes equivalent to:

```text
content_learning_state(content_type, completed_at)
content_learning_state(content_type, listened_at)
content_learning_state(last_played_at)
favorite(content_type, created_at)
```

Exact SQLite index shape is qualified against real repository queries.

---

## 18. Repository contract

Recommended application abstraction:

```text
LearnerContentStateRepository
```

Conceptual operations:

```text
watchState(contentCode, contentType)
markListened(...)
updatePlaybackPosition(...)
markCompleted(...)
markNotCompleted(...)
toggleFavorite(...)
queryByMarker(...)
```

Presentation SHALL consume one composed marker state rather than coordinating several Drift tables directly.

Suggested view model/value object:

```text
ContentMarkerState
├── isFavorite
├── isListened
├── listenedAt
├── isCompleted
├── completedAt
└── lastPosition
```

---

## 19. State changes and Riverpod

Riverpod controllers/providers observe durable marker state.

Flow:

```text
user/playback event
→ feature/application controller
→ LearnerContentStateRepository
→ Drift transaction
→ reactive query/provider
→ Material UI updates
```

The UI SHALL NOT optimistically leave durable state inconsistent after a failed local write.

---

## 20. Tombstone/cache behavior

Backend tombstone:

```text
remove/hide disposable CURRENT content
release cache asset references
```

but preserve:

```text
favorite
content_learning_state
review history
test history
```

If the logical content later returns with the same stable code, the local state can be resolved again according to product policy.

---

## 21. Privacy

These markers remain device-local in MVP.

Do not send to Backend merely for analytics/personalization:

```text
favorites
listened history
completed history
last playback position
```

This preserves the current rule that installation identity is not a learner-profile identity.

---

## 22. Acceptance scenarios

Must prove at least:

1. completed item remains completed after restart;
2. listened item remains listened after audio cache eviction;
3. favorite survives content/media cache eviction;
4. favorite does not pin MP3 automatically;
5. partially played audio remains NOT_LISTENED but can resume;
6. completed + favorite + listened can coexist;
7. mark-not-completed does not delete test/review history;
8. tombstone hides content while durable marker state remains stored;
9. Not completed/Listened/Favorites filters return correct local results;
10. markers remain usable at text scale 2.0;
11. marker meaning is accessible without relying only on color;
12. adaptive resize preserves the same marker state.

---

## 23. Final rule

```text
FAVORITE  = user curation
LISTENED  = audio consumption
COMPLETED = pedagogical completion
```

They are durable, independent learner states and are rendered consistently through the CareerSpeak Material Design 3 component system.