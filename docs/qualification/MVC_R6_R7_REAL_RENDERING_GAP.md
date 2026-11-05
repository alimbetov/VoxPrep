# MVC-R6 → MVC-R7: exact Flutter rendering gap and acceptance

Status: **OPEN**. R7 first learner rendering slice implemented for five existing Flutter types; Question/PracticeTest remain separate contracts. Device/end-to-end acceptance and exact-SHA CI are pending. No generated mock screenshots are acceptance.

## Source evidence

- Backend `ContentRevisionSnapshot.Body` supports seven typed variants: Vocabulary, Interview, Topic, Phrase, Shadowing, Question, PracticeTest.
- Flutter `mobile/careerspeak_app/lib/domain/content_item.dart` has five ordinary lesson `ContentType` members: vocabulary, interview, topic, shadowing, phrase. **Question/PracticeTest are represented separately** in `domain/assessment.dart`, `data/remote/assessment_payload_decoder.dart` and `features/tests/test_session_screen.dart`; absence from `ContentType` alone is not evidence the app lacks test UI.
- Flutter `features/content/content_detail_panel.dart` currently renders common metadata, learner markers, generic audio or Interview role audio and description. It does **not** render all typed body fields.
- Therefore ordinary learner-visible lessons previously did not render typed body fields. The existing assessment pathway must be qualified against Backend editorial questions/tests and linked to the same published exact-revision contract; it should not be duplicated as an ordinary lesson.

## Implemented R7 first slice (pending qualification)

- Flutter `DriftTypedContentReader` reads exact typed payload already written by `DriftSyncPlanExecutor` into `typed_content_reads`; joins exact revision with `content_catalog_reads` and compares immutable checksums, body kind and visible canonical metadata.
- The existing production `ContentPayloadDecoder` validates the reconstituted typed payload. Invalid/corrupt payloads fail closed, with no invented body data.
- `typedContentByIdentityProvider` requires entitlement-aware `contentByIdentityProvider` to succeed before retrieving typed body. No new public endpoint or broader FULL entitlement access introduced.
- Actual `ContentDetailPanel` renders Vocabulary, Phrase, Interview, Topic and Shadowing using `TypedContentBodyCard`. Includes exact transcript and segment timing; does **not** add microphone, recording or speech-scoring functionality.
- Widget tests cover all five body types; Drift tests cover exact read, absent legacy body and checksum mismatch.
- DB schema unchanged (uses existing `typed_content_reads` table). All changes require exact-SHA Flutter CI and offline device acceptance.

## Required R7 production path

```text
Backend revision typed body / localizations / assets
→ published immutable manifest + pack / API
→ Flutter contract decoder and local Drift persistence
→ typed learner-detail widgets (7)
→ reopen offline + entitlement gate
→ real phone screenshots compared to backend source
```

Each typed view must use exactly the published payload, not a hand-crafted MVC presentation or simulated speech scoring.

## Acceptance matrix

| Type | Required learner rendering | Test evidence |
| --- | --- | --- |
| Vocabulary | Term, part of speech, definition, ordered examples, pronunciation audio if published | Decode/persist/widget/offline |
| Phrase | Phrase, usage, ordered examples, pronunciation audio if published | Decode/persist/widget/offline |
| Interview | Prompt, model answer, ordered key points, distinct Question/Sample Answer role clips | Decode/persist/widget/audio/offline |
| Topic | Ordered sections with heading/text, optional narration | Decode/persist/widget/offline |
| Shadowing | Transcript, ordered segments with optional start/end; published audio; **no microphone scoring** | Decode/persist/widget/audio/offline |
| Question (assessment domain) | Actual assessment prompt, ordered choices, feedback/explanation; use existing assessment decoder and session UI | Backend editor → assessment payload → Drift → test UI/offline |
| Practice Test (assessment domain) | Existing session navigator and scoring, exact referenced Question revisions and configured passing threshold | Backend editor → frozen assessment refs → Drift → test UI/scoring/offline |

## Non-negotiable business/security rules

- FREE/FULL is inherited from Collection, not independently invented per content revision.
- No client-side generated unlocks. Full access must follow backend entitlement and Store verification policy, including offline rule.
- Practice tests must resolve only approved exact Question revisions and preserve ordering.
- No fictional user microphone, speech recognition or pronunciation evaluation controls.
- Revision and payload checksums must remain stable across HTTP, Drift cache and offline reopen.
- Published content is immutable; editors must create a new draft revision to change material.

## Work remaining

1. Qualify the existing five ordinary lesson types on real published payloads through Drift, widgets and offline reopen (first local reader/widget slice is implemented).
2. Qualify the separate existing Question/PracticeTest assessment decoders, repositories, learner sessions, scoring and revision references against Backend MVC outputs. Integrate navigation without duplicating assessment models.
3. Add exact published fixture E2E per type and offline reopen tests.
4. Add MVC read-only preview backed by the same typed fixtures, explicitly label any approximation until parity proven.
5. Record screenshots from actual Flutter renderer on devices/emulators and compare with approved content.
6. Qualify real Backend→Piper→RustFS→MVC MP3 playback (R6): do not substitute a mocked MP3.
7. Hold release/merge gates independent of real Google Play / Apple sandbox and restore/revoke acceptance.
