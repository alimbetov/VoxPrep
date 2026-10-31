# C2 Qualification Ledger

C1 is frozen at `4620142f28de20bc0bf84b686d879fd082df7e95` and is not modified by C2.

## C2.1 / C2.2 — typed domain and small catalogue components

Qualified source baseline:

```text
4d3597447e933724c06c2dcc4c75c9b46aab248e
```

Production qualification:

```text
Flutter Production Adapters run 41193064139
format                         PASS
Drift v6 reproducibility       PASS
flutter analyze                PASS
full flutter test              PASS
```

C2 freezes the five typed canonical bodies plus the small product catalogue shapes:

```text
VOCABULARY
INTERVIEW
TOPIC
PHRASE
SHADOWING

LearningGoal
LearningTrack
LearningCollection
Category
Level
Skill
SupportedLocale
TtsVoice
```

## C2.3 — production typed canonical-content decode

Production typed source:

```text
2a1a478942ad16c075556a8e01cecb819a6f9fb7
```

The production decoder requires `skillCodes` and exactly one typed `body`, enforces `contentType == body.kind`, rejects unsupported body fields and rejects legacy untyped server payloads.

Final clean qualification:

```text
Flutter Production Adapters run 41194357802
format                         PASS
Drift v6 reproducibility       PASS
flutter analyze                PASS
full flutter test              PASS
```

## C2.4 — Drift typed-body persistence

Qualified production implementation:

```text
eba871d51edb8dc6d4fb5425e7a13374246e6a30
feat(c2): persist typed content revisions in Drift v7
```

The C2 persistence model is deliberately separate from the accepted C1 read model:

```text
ContentCatalogReads   = C1 presentation projection, unchanged
TypedContentReads     = C2 exact-revision typed projection
```

Schema `v7` adds `TypedContentReads` without rewriting C1 tables. Production sync writes the typed projection atomically with the exact canonical content revision.

Qualification run:

```text
C2.4 Drift Typed Persistence V3 Once
run 41195169657
Drift v7 generation              PASS
flutter analyze                  PASS
targeted decoder/persistence     PASS
v1/v2/v3/v5/v6 -> v7 migration   PASS
file-backed close/reopen         PASS
full flutter test                PASS
production commit                PASS
```

Permanent production gate was then switched to Drift v7 and all C2.4 staging tooling was removed:

```text
0ae70c1143d681b1be2090ff4c207cbb4839ef0c
chore(c2): finalize Drift v7 production gate
```

## C2.5 — adversarial typed content + catalogue fallback

Implementation candidate:

```text
700633663ce84398b034190514f7990d01d9039b
test(c2): harden typed content and catalogue fallback
```

The adversarial matrix now verifies all five frozen body kinds through the production decoder and keeps fail-closed behavior for discriminator/type mismatches, malformed body fields and duplicate/invalid catalogue identities.

Catalogue selection semantics are deterministic:

```text
active selected code       -> keep selected code
missing/inactive selection -> active choice by sortOrder, then stable code
no active choice           -> null
identity duplicates        -> fail closed
```

The first production attempt exposed only a package-aware formatting difference in `catalogue_selection.dart`. No C2 runtime semantic was changed. The official Flutter-package formatter produced:

```text
d2bc610b4a0b76c2aa921d0c4fd6689366fa051e
style(c2): apply official catalogue formatter
```

The one-shot formatter workflow has been removed. This ledger commit is the clean-head trigger for the final C2.5/C2.6 production qualification.

## C2.6 — exact-SHA final production qualification

Acceptance requires one clean `Flutter Production Adapters` run on the final C2 tree with:

```text
format                         PASS
Drift v7 reproducibility       PASS
flutter analyze                PASS
full flutter test              PASS
```

Only after that exact-SHA gate is green may C2 be marked `ACCEPTED` and `BGA-003`, `BGA-007`, `BGA-008`, `BGA-016` be marked contract-closed.
