# VoxPrep / CareerSpeak Backend v1 — Domain Composition

**Status:** normative domain-design companion to `BACKEND_V1_SYSTEM_DESIGN_SPEC.md`

## 1. Decision summary

The selected composition is **CQRS-lite Authoring + Immutable Learner Publication**.

The model exists to satisfy two materially different external consumers without duplicating business truth:

```text
Flutter -> immutable learner read model
Worker  -> exact TTS execution model
ADMIN   -> mutable authoring/moderation model
```

The Backend domain must not be shaped as a direct mirror of Flutter DTOs or Worker DTOs.

## 2. Context map

```text
Identity -------> Access
   |                |
   |                v
   |           Entitlement
   |
   +----------------------------------------+
                                            |
Catalogue ---> Content ---> Media <--- TTS  |
    |            |          ^        |      |
    |            v          |        |      |
    |        Localization   |        |      |
    |                       |        |      |
    +------> Assessment     |        |      |
              |             |        |      |
              +-------------+--------+------+
                            |
                            v
                       Publication
                            |
                            v
                         Flutter
```

TTS production is intentionally outside learner publication lifecycle until its output is READY, reviewed/bound and selected into a publication candidate.

## 3. Aggregate inventory

### 3.1 Identity context

#### Installation

Purpose: stable device-installation identity and authorization root.

Suggested attributes:

```text
internalId
installationId UUID/public stable identity
status ACTIVE|BLOCKED|REVOKED
tokenVersion
createdAt
lastSeenAt
```

Optional operational metadata may include platform/app version but must not become product identity.

Invariants:

- `installationId` unique;
- registration of the same installation is idempotent;
- credential renewal does not delete learner state;
- blocked/revoked installation cannot access authenticated learner API.

Credential token storage may remain stateless JWT-based or use a small credential table; this is an implementation decision provided revocation/version rules remain enforceable.

### 3.2 Access context

#### PurchaseVerificationRecord

Purpose: replay-safe processing record for Store verification attempts/events.

Suggested attributes:

```text
id
installationId
provider GOOGLE_PLAY|APP_STORE
productId
purchaseEventId
proofFingerprint
status VERIFIED|REJECTED|ERROR
verifiedAt
createdAt
```

Invariants:

- unique provider + purchaseEventId;
- replay with identical semantic request returns prior result;
- conflicting reuse returns contract-defined conflict;
- plaintext verification proof is not logged and should not be retained unless strictly necessary.

#### Entitlement

Purpose: Backend access truth independent of Store transaction mechanics.

Suggested attributes:

```text
id
installationId
accessLevel FREE|FULL
source DEFAULT|GOOGLE_PLAY|APP_STORE|ADMIN
sourceReference
validFrom
revokedAt
```

MVP may maintain one effective entitlement per installation. Future subscription/expiry semantics must not be predesigned unless needed.

### 3.3 Catalogue context

#### Vertical
#### LearningGoal
#### LearningTrack
#### LearningCollection

These are mutable authoring identities/projections used by ADMIN.

Relationships:

```text
Vertical 1--N LearningGoal
LearningGoal 1--N LearningTrack
LearningTrack 1--N LearningCollection
```

`LearningCollection` owns mutable working membership until a catalogue/publication revision is frozen.

#### LearningCollectionMember

Suggested semantics:

```text
position
memberType CONTENT|PRACTICE_TEST
contentCode/contentRevision OR practiceTestCode/practiceTestRevision
```

Invariants:

- positions contiguous from zero in an approved revision;
- exactly one target according to type;
- target belongs to the same allowed vertical/product context;
- accessLevel is explicit FREE|FULL and never inferred.

#### CatalogueRevision / materialized catalogue

The learner-facing catalogue payload is an immutable materialized revision with:

```text
kind
revision
checksum
canonical items bytes/projection
```

It may be stored as normalized exact membership plus canonical JSON bytes/checksum or regenerated deterministically from immutable refs. Whichever approach is selected, published bytes must be reproducible.

### 3.4 Content context

#### Content

Stable business identity:

```text
id
code unique business code
type VOCABULARY|INTERVIEW|TOPIC|PHRASE|SHADOWING
createdAt
```

#### ContentRevision

Suggested attributes:

```text
id
contentId
revision positive int
status
checksum
canonical learner fields
body discriminator + typed body persistence
createdAt
approvedAt
publishedAt
version optimistic-lock field while mutable
```

Invariants:

- unique content + revision;
- published/approved frozen bytes are not edited in place;
- exact checksum matches canonical learner projection;
- body kind matches content type;
- learner-facing labels/metadata satisfy contracted validation.

Typed body persistence may use normalized subtype tables or JSON/embeddable storage. The selection must preserve validation/type safety and PostgreSQL/H2 portability for dev. Do not use one unrestricted generic metadata map as the primary domain model.

#### ContentLocalizationRevision

Suggested attributes:

```text
id
contentRevisionId
locale
localizationRevision
checksum
title nullable
subtitle nullable
description nullable
translation nullable
hint nullable
explanation nullable
status
```

Invariants:

- unique canonical content revision + locale + localizationRevision;
- at least one meaningful localized field when approved;
- canonical English/shared media are not duplicated;
- approved/published locale revision immutable.

### 3.5 Assessment context

#### Question

Stable identity: `questionCode`.

#### QuestionRevision

MVP body:

```text
singleChoice
prompt
options
correctOptionIndex
skillCode
explanation
```

Invariants:

- immutable after approval/publication;
- checksum exact;
- correctOptionIndex inside options range;
- option ordering semantic.

#### PracticeTest

Stable identity: `practiceTestCode`.

#### PracticeTestRevision

Suggested attributes:

```text
revision
checksum
title
subtitle
mode
passingScoreBasisPoints
status
```

#### PracticeTestQuestionRef

```text
order
questionCode
questionRevision
questionChecksum
points
```

Invariants:

- order contiguous;
- refs exact and immutable;
- deterministic scoring inputs frozen;
- content is not directly owned by PracticeTest in MVP.

### 3.6 Media context

#### FileAsset

Central binary asset identity shared by learner media, TTS models/configs and TTS outputs.

Suggested attributes:

```text
id UUID/public assetId or fileId
kind CONTENT_COVER|CONTENT_AUDIO|TTS_MODEL|TTS_CONFIG|TTS_OUTPUT|MODEL_CARD|OTHER
status PENDING|READY|FAILED|QUARANTINED|DELETED
mediaType
extension
sizeBytes
sha256
durationMs nullable
storageBucket/internal namespace
storageObjectKey internal
createdAt
readyAt
```

Invariants:

- READY bytes immutable;
- storage coordinates never leak as client authorization/locator;
- checksum/size match stored bytes;
- replacement allocates new asset identity.

#### ContentAssetBinding

Links exact content revision to exact asset and semantic role.

Suggested attributes:

```text
contentRevisionId
assetId
role coverImage|primaryAudio|...
status/active binding where needed
createdAt
```

For an exact approved/published content revision, role cardinality follows contract rules (for example max one cover image).

### 3.7 TTS context

#### TtsVoice

Product-facing voice identity:

```text
id
code unique
displayName
language/locale
accent nullable
gender nullable
style nullable
enabled
defaultModelId nullable
```

Flutter may eventually receive a learner-facing projection only; Worker does not select arbitrary voices.

#### TtsVoiceModel

Immutable exact technical model revision.

Suggested attributes:

```text
id UUID
code unique
voiceId
engine PIPER
engineVersion
modelVersion
quality
sampleRateHz nullable
speakerCount nullable
modelAssetId
configAssetId
modelCardAssetId nullable
modelSha256
configSha256
sourceProvider
sourceRepository
sourceRevision
sourceKey
licenseName nullable
licenseReference nullable
commercialUseReviewed
status
createdAt
approvedAt
activatedAt
```

Lifecycle:

```text
DISCOVERED
DOWNLOADING
VALIDATING
READY_FOR_REVIEW
APPROVED
ACTIVE
DEPRECATED
INVALID
QUARANTINED
```

Only ACTIVE models may be selected for new jobs. Existing jobs preserve exact selected model even after deprecation/default change.

#### TtsModelProvisioningAttempt

Audit/process entity for model acquisition; not Worker-facing.

Suggested attributes:

```text
id
seedCode/source identity
requestedAt
startedAt
completedAt
status
resolvedSourceRevision
resolvedModelSha256
resolvedConfigSha256
errorCode/errorMessage safe
```

Use this for observability/audit; do not make it the model aggregate root.

#### TtsJob

Durable queue aggregate.

Required frozen fields align with Worker contract:

```text
id jobId UUID
fileId output pending FileAsset identity
contentType
contentRevisionId
content/audio role
voiceId
voiceModelId
speakerId nullable
normalizedTtsText
language
audioProfile
fingerprint
fingerprintVersion
status PENDING|RUNNING|READY|FAILED|CANCELLED|SUPERSEDED
attemptCount
workerId nullable
leaseTokenHash/raw protected representation
leaseUntil nullable
createdAt
startedAt
completedAt
errorCode nullable
errorMessage nullable
```

The lease is part of the TtsJob aggregate in MVP; no durable WorkerNode/registration aggregate is required because the frozen Worker contract does not define Worker registration.

Invariants:

- all execution inputs frozen before PENDING;
- Backend computes fingerprint;
- each claim/reclaim creates new lease token;
- heartbeat/fail/output require current unexpired ownership;
- stale lease cannot finalize output;
- same READY fingerprint should be reused where policy permits;
- changed execution input creates new fingerprint and new job/output asset;
- retry policy owned by Backend.

### 3.8 Publication context

#### Publication

Immutable learner snapshot identity.

Suggested attributes:

```text
id UUID/internal
contentVersion long never reused
schemaVersion
status CANDIDATE|VALIDATING|READY|PUBLISHED|SUPERSEDED|FAILED
checksum
publishedAt nullable
createdAt
```

#### PublicationPointer

Singleton/logical pointer to current published publication.

Suggested attributes:

```text
name = LEARNER_CURRENT
publicationId
version optimistic lock
updatedAt
```

This is preferred over encoding mutable CURRENT status into many publication rows. Atomic switch updates one pointer after candidate persistence/validation.

#### PublicationPackRef
#### PublicationCatalogueRef
#### PublicationContentRef
#### PublicationAssessmentRef

These store exact immutable membership/revision/checksum references required to reproduce the learner root/pack/catalogue payloads.

The exact normalized table split may follow the wire contract and query needs, but publication never owns mutable authoring data.

#### PublicationTombstone / removal projection

Represents contracted removal/deactivation semantics where required by the root manifest.

## 4. Moderation/application composition

There is one ADMIN actor, but review remains a first-class workflow.

Recommended cross-module audit projection:

#### ReviewRecord

```text
id
subjectType CONTENT_REVISION|QUESTION_REVISION|PRACTICE_TEST_REVISION|TTS_MODEL|PUBLICATION
subjectId
subjectRevision nullable
decision APPROVED|REJECTED|CHANGES_REQUESTED
comment nullable
actedAt
actor = ADMIN
```

Rules:

- the subject aggregate owns state transitions;
- ReviewRecord records the decision, it does not override subject invariants;
- ADMIN MVC may provide one unified moderation queue built from module query projections.

## 5. Aggregate boundaries and cross-context references

Prefer references by stable/exact IDs rather than JPA object graphs across bounded contexts.

Examples:

```text
TtsJob.contentRevisionId     -> exact Content revision identity
TtsJob.voiceModelId          -> exact TTS model
ContentAssetBinding.assetId  -> FileAsset
PublicationContentRef        -> exact Content revision/checksum
PublicationAssessmentRef     -> exact Assessment revision/checksum
Entitlement.installationId   -> Installation public identity
```

Avoid giant cross-module `@ManyToOne` graphs that make transactions/navigation accidental.

Cross-context invariant checks belong in application/domain services using ports/queries.

## 6. JPA/persistence design principles

1. Aggregate roots use repositories; child entities are normally persisted through their aggregate.
2. Do not expose JPA entities to controllers or Thymeleaf templates where it couples lazy loading/domain state.
3. Use explicit DTO/view models for ADMIN forms and learner/Worker APIs.
4. Keep `open-in-view=false`.
5. Collections that are semantically ordered must have explicit stable position/order columns.
6. Use optimistic locking on mutable authoring aggregates.
7. Immutable revision uniqueness is enforced in DB.
8. Database cascade/delete rules must not erase published history.
9. Soft lifecycle/archive is preferred over deleting exact published identities.

## 7. Candidate logical tables

This is a design inventory, not final Liquibase DDL.

```text
installation
purchase_verification
entitlement

vertical
learning_goal
learning_track
learning_collection
learning_collection_member
catalogue_revision
catalogue_revision_item (or typed revision membership tables)

content
content_revision
content_localization_revision
content_asset_binding

question
question_revision
practice_test
practice_test_revision
practice_test_question_ref

file_asset

tts_voice
tts_voice_model
tts_model_provisioning_attempt
tts_job

review_record

publication
publication_pointer
publication_pack_ref
publication_catalogue_ref
publication_content_ref
publication_assessment_ref
publication_tombstone
```

Do not add tables merely because a DTO has a nested object. Persist domain truth, not JSON shape.

## 8. Initial model provisioning composition

A configured seed is a value/config object, not necessarily a table:

```text
TtsModelSeedDefinition
  code
  required
  autoActivate
  sourceProvider
  sourceRepository
  sourceRevision
  selector:
    locale
    voiceName
    quality
```

Initial candidates:

```text
en-us-lessac-high      -> en_US / lessac / high
de-de-thorsten-high    -> de_DE / thorsten / high
tr-tr-fahrettin-medium -> tr_TR / fahrettin / medium
es-mx-claude-high      -> es_MX / claude / high
es-es-davefx-medium    -> es_ES / davefx / medium
```

`TtsModelCatalogGateway` resolves acquisition metadata. `TtsModelProvisioningService` owns download/validation/import. `TtsVoiceModel` becomes Backend truth only after successful validation/persistence.

External URLs are not primary model identity and are never returned to Worker.

## 9. Publication eligibility

A candidate may include only data satisfying module-owned eligibility rules.

Examples:

- ContentRevision approved and immutable;
- LocalizationRevision valid if referenced;
- PracticeTestRevision approved and all exact Question revisions resolvable;
- collection membership exact and same product/vertical rules valid;
- referenced learner FileAssets READY and checksum-known;
- required TTS audio READY/approved where content policy requires it;
- accessLevel valid;
- no invalid/quarantined TTS model affects a new generation requirement;
- schema/client compatibility satisfied.

Publication validation must produce deterministic machine-readable findings suitable for ADMIN preview.

## 10. Recommended command/query services

Representative application use-cases:

```text
RegisterInstallation
VerifyPurchase
ResolveEffectiveEntitlement

CreateContent
CreateContentRevision
EditDraftContentRevision
SubmitContentRevisionForReview
ApproveContentRevision
CreateLocalizationRevision

CreateQuestionRevision
CreatePracticeTestRevision
ApproveAssessmentRevision

UploadFileAsset
BindContentAsset

DiscoverTtsModels
ProvisionTtsModel
ApproveTtsModel
ActivateTtsModel
RequestTtsAudio
ClaimTtsJob
HeartbeatTtsJob
FailTtsJob
FinalizeTtsOutput

BuildPublicationCandidate
ValidatePublicationCandidate
PreviewPublicationDiff
PublishCandidate
GetCurrentPublication
```

Queries/read projections may be optimized separately without changing aggregate ownership.

## 11. Domain acceptance questions

Before JPA DDL is frozen, resolve and test:

1. Which exact content types require TTS audio before publication versus allow audio-optional publication?
2. Whether catalogue revisions are stored as canonical JSON plus typed refs, normalized rows, or both.
3. Whether ADMIN may approve and publish in one action or publication approval is always separate.
4. Exact lifecycle for replacing an already-published audio binding.
5. Exact Store entitlement revocation/restore rules once real provider APIs are implemented.
6. Whether TTS model commercial-use review is an explicit required production gate for all seeded models.

None of these questions blocks B1 foundation, Identity or basic authoring skeleton. They must be closed before their corresponding production slice is declared accepted.
