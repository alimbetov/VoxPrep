# 02 — Backend Domain Model

**Status:** FROZEN DESIGN INPUT

## 1. Catalogue domain

Core business entities:

```text
Vertical
LearningGoal
LearningTrack
LearningCollection
```

Each entity has a stable business `code` and authoring lifecycle.

Recommended ownership:

```text
Vertical
 └── Goal refs
      └── Track refs
           └── Collection refs
```

Learner delivery does not expose mutable catalogue rows directly. Publication references immutable revisioned catalogue projections.

## 2. Content domain

Conceptual model:

```text
Content
├── business identity: (contentType, contentCode)
└── ContentRevision[]
      ├── revision
      ├── immutable shared metadata
      ├── typed body
      ├── checksum
      ├── lifecycle
      └── asset refs
```

Supported MVP content types include at least:

```text
VOCABULARY
INTERVIEW
TOPIC
PHRASE
SHADOWING
```

Do not use generic EAV as the primary content model.

Use a shared revision envelope plus type-specific body model.

Example conceptual bodies:

```text
VocabularyBody
- term/lemma
- explanation/definition
- usage/examples

InterviewBody
- question/prompt
- model answer
- key points/guidance

TopicBody
- structured sections
- body / learning objectives

PhraseBody
- canonical English phrase
- usage/examples

ShadowingBody
- canonical transcript
- ordered segments
- optional timing/alignment metadata
```

Exact field sets must stay compatible with Flutter decoders/contract fixtures.

## 3. Localization domain

Localization is not a translated clone of canonical content.

Conceptual identity:

```text
(contentType,
 contentCode,
 canonicalContentRevision,
 locale,
 localizationRevision)
```

`ContentLocalizationRevision` contains learner-support text such as:

```text
translation
hint
explanation
localized title/description/support text
```

Canonical English/audio identity remains separate and reusable across locales.

## 4. Assessment domain

```text
PracticeTest
└── PracticeTestRevision
      ├── revision
      ├── checksum
      └── ordered exact QuestionRevision refs

Question
└── QuestionRevision
      ├── revision
      ├── immutable question body
      └── deterministic scoring data
```

A published PracticeTestRevision MUST remain reproducible indefinitely against the exact QuestionRevisions it referenced.

No later edit may rewrite an older published revision.

## 5. Publication domain

Conceptual aggregate:

```text
PublicationSnapshot
├── contentVersion
├── schemaVersion
├── publishedAt
├── checksum
├── exact Pack refs
├── exact Catalogue refs
├── exact PracticeTest refs
└── Tombstones
```

Recommended related concepts:

```text
PublicationPackRef
PublicationCatalogueRef
PublicationPracticeTestRef
Tombstone
CurrentPublicationPointer
```

PublicationSnapshot is immutable after commit.

## 6. Media domain

```text
FileAsset
├── assetId
├── mediaType
├── sizeBytes
├── checksumSha256
├── deliveryKey
├── storage state
└── created/ready timestamps

ContentAssetRef
PackAssetRef
```

`deliveryKey` is backend-internal storage metadata, never a Flutter URL.

A FileAsset can become learner-visible only when it is valid for a published exact revision/publication membership.

## 7. Installation security domain

```text
Installation
├── installationId
├── status: ACTIVE | REVOKED
├── createdAt
├── lastSeenAt
├── tokenIssuedAt
└── currentTokenVerifier
```

`installationId` identifies one app installation, not a person or physical device.

Plaintext token persistence is discouraged; store a verifier/hash appropriate for authentication.

## 8. TTS domain

```text
TtsVoice
TtsVoiceModel
TtsJob
```

TtsJob needs at least:

```text
jobId
status
input/fingerprint identity
voice/model identity
attempt count
leaseToken
leaseUntil
claimedBy/workerId audit label
createdAt / updatedAt
output FileAsset ref
failure code/details safe for operations
```

Concurrency must support atomic claim via `FOR UPDATE SKIP LOCKED`.

## 9. Identity and uniqueness constraints

At design level enforce:

```text
Vertical.code unique
LearningGoal.code unique
LearningTrack.code unique
LearningCollection.code unique

(contentType, contentCode, revision) unique
(contentType, contentCode, contentRevision, locale, localizationRevision) unique
(practiceTestCode, revision) unique
(questionCode, revision) unique

PublicationSnapshot.contentVersion unique
FileAsset.assetId unique
Installation.installationId unique
```

If code namespaces are intentionally scoped differently, the scope must be explicit and stable in the public contract.

## 10. Immutability rule

From learner-delivery perspective:

```text
published revision = append-only immutable fact
```

Correction flow:

```text
edit authoring data
→ create new revision
→ validate
→ publish new snapshot
```

Never mutate old published rows to “fix” learner history.