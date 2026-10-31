# C2 Typed Content + Small Product Catalogues

**Status:** ACTIVE CONTRACT IMPLEMENTATION  
**Baseline:** C1 accepted at `4620142f28de20bc0bf84b686d879fd082df7e95`  
**C2 contract source baseline:** `f9d51defbdf7e1ff7027b32a72d0f2834d8a617c`  
**Normative component contract:** `contracts/c2-content-catalog-v1.yaml`

## 1. Scope

C2 closes the design space for:

```text
BGA-003 typed content body
BGA-007 taxonomy
BGA-008 locale / learner-facing voice capability
BGA-016 checksum canonicalization
```

C2 does **not** define backend JPA entities and does not add learner catalogue endpoints yet. Endpoint/publication wiring belongs to C4. Assessment body/scoring remains C3.

The minimal product hierarchy remains:

```text
LearningGoal
    ↓
LearningTrack
    ↓
LearningCollection
    ↓
ContentRevisionRef / PracticeTestRevisionRef
```

There is no `LearningActivity`, workflow engine, recommendation layer or generic EAV content model.

## 2. Typed canonical content

Every immutable canonical content revision has one shared envelope plus exactly one typed body matching `contentType`.

```text
TypedContentPayload
├── stable identity + revision + checksum
├── title / subtitle / description
├── categoryCode / levelCode / skillCodes[]
├── minutes / hasAudio
└── body
    ├── VocabularyBody
    ├── InterviewBody
    ├── TopicBody
    ├── PhraseBody
    └── ShadowingBody
```

The body discriminator is `kind`. `contentType` and `body.kind` MUST match exactly. Unknown kinds, mismatches and unknown body fields fail closed.

### VocabularyBody

```text
term
definition
partOfSpeech?
examples[]  // at least one
```

### InterviewBody

```text
prompt
modelAnswer
keyPoints[] // at least one
```

### TopicBody

```text
sections[]
  heading
  text
```

### PhraseBody

```text
phrase
usage
examples[] // at least one
```

### ShadowingBody

```text
transcript
segments[]
  order
  text
  startMs?
  endMs?
```

`segments` are strictly ordered by `order`. Timing is optional, but `startMs` and `endMs` are either both absent or both present. When present: `0 <= startMs < endMs`, and timed segments must not overlap.

## 3. Small backend-owned catalogues

Only these C2 catalogue projections are frozen:

```text
LearningGoal
LearningTrack
LearningCollection
Category
Level
Skill
SupportedLocale
TtsVoice
```

Stable code is identity. Labels/titles/descriptions are presentation. `active=false` removes an item from new selection but does not rewrite local learner history.

`LearningTrack.careerTrackCode` is optional and preserves the product distinction:

```text
CareerTrack != LearningTrack
```

C2 does not introduce a new CareerTrack aggregate; the optional code is a taxonomy reference until a concrete backend catalogue is justified.

`LearningCollection` contains ordered exact revision refs. It must contain at least one content or practice-test reference. Practice-test body semantics remain deferred to C3.

`TtsVoice` exposes learner capability only:

```text
code
locale
accentCode
label
sortOrder
active
```

Piper model paths, checksums, Worker lease data and RustFS keys are not learner-facing voice fields.

## 4. Checksum canonicalization — BGA-016

All immutable learner JSON projections that carry a self checksum use the same rule:

```text
SHA-256(
  UTF-8(
    RFC 8785 JSON Canonicalization Scheme(
      projection with its own top-level `checksum` member omitted
    )
  )
)
```

This applies to root, pack, canonical content, localized content and future immutable catalogue/publication projections when they carry a checksum.

Rules:

```text
object member order      non-semantic; JCS canonical order is hashed
array order              semantic and preserved
insignificant whitespace not hashed
self checksum            omitted from its own digest input
nested ref checksums      included normally
hex output                lowercase 64-character SHA-256
strings                   publication input must be NFC-normalized
integers                  emitted as JSON integers where schemas require integer
```

The backend publication path owns NFC normalization/validation before hashing. Flutter compares exact published checksums; it must not silently rewrite payload text before identity validation.

ETag may quote the root checksum, but ETag syntax is transport metadata and is not part of the root digest input.

## 5. Flutter contract boundary

C2 Flutter domain types mirror contract semantics, not backend persistence entities. They intentionally have no database annotations and no HTTP concerns.

The current C1 `ContentPayload` remains untouched in this first C2 slice. The next C2 slice will migrate the production decoder/gateway to `TypedContentPayload` semantics and then add offline persistence. This avoids partially changing the accepted C1 wire path before the typed-body contract is executable and tested.

## 6. C2 implementation slices

```text
C2.1 typed body domain + component contract              ← CURRENT
C2.2 Goal/Track/Collection + capability catalogue domain ← CURRENT
C2.3 production ContentPayload decoder/gateway cutover   NEXT
C2.4 Drift typed-body/catalogue persistence              NEXT
C2.5 adversarial checksum/type mismatch qualification    NEXT
C2.6 exact-SHA full production CI                        REQUIRED
```

## 7. Acceptance

C2 is accepted only when all are true:

```text
[ ] all five body kinds are explicit and fail closed
[ ] contentType == body.kind is enforced on production decode
[ ] Goal → Track → Collection shapes are frozen
[ ] Category / Level / Skill shapes are frozen
[ ] SupportedLocale / TtsVoice learner projections are frozen
[ ] no Worker model internals leak into TtsVoice
[ ] RFC 8785 checksum scope is frozen
[ ] typed content survives Drift offline/restart
[ ] catalogue selection degrades safely when an item becomes inactive
[ ] exact-SHA production CI is green
```

Only after C2 acceptance should `BGA-003`, `BGA-007`, `BGA-008` and `BGA-016` be marked contract-closed.
