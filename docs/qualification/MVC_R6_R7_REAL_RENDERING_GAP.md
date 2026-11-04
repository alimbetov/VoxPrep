# MVC-R6 → MVC-R7: exact Flutter rendering gap and acceptance

Status: **OPEN**, based on actual source inspection in `main` after R5 PR #48 merge. No generated mock screenshots are acceptance.

## Source evidence

- Backend `ContentRevisionSnapshot.Body` supports seven typed variants: Vocabulary, Interview, Topic, Phrase, Shadowing, Question, PracticeTest.
- Flutter `mobile/careerspeak_app/lib/domain/content_item.dart` has only five `ContentType` members: vocabulary, interview, topic, shadowing, phrase.
- Flutter `features/content/content_detail_panel.dart` currently renders common metadata, learner markers, generic audio or Interview role audio and description. It does **not** render all typed body fields.
- Therefore Flutter's learner-visible lesson cannot yet be claimed equivalent to Backend MVC Content Studio. Especially Question/PracticeTest cannot be previewed faithfully without new Flutter domain/decoder/persistence/UI work.

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
| Question | Question text, ordered choices, correctness handling appropriate to learner mode, explanation | Decode/persist/widget/answer feedback/offline |
| Practice Test | Instructions, percentage threshold, exact referenced Question revisions, deterministic scoring, review | Decode/references/persist/widget/scoring/offline |

## Non-negotiable business/security rules

- FREE/FULL is inherited from Collection, not independently invented per content revision.
- No client-side generated unlocks. Full access must follow backend entitlement and Store verification policy, including offline rule.
- Practice tests must resolve only approved exact Question revisions and preserve ordering.
- No fictional user microphone, speech recognition or pronunciation evaluation controls.
- Revision and payload checksums must remain stable across HTTP, Drift cache and offline reopen.
- Published content is immutable; editors must create a new draft revision to change material.

## Work remaining

1. Update Dart domain, payload parsers and Drift mappings to cover all seven types without losing typed bodies.
2. Add production type-specific learner widgets and tests (including Question & Practice Test).
3. Add exact published fixture E2E per type and offline reopen tests.
4. Add MVC read-only preview backed by the same typed fixtures, explicitly label any approximation until parity proven.
5. Record screenshots from actual Flutter renderer on devices/emulators and compare with approved content.
6. Qualify real Backend→Piper→RustFS→MVC MP3 playback (R6): do not substitute a mocked MP3.
7. Hold release/merge gates independent of real Google Play / Apple sandbox and restore/revoke acceptance.
