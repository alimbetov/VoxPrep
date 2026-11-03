# CareerSpeak — Content Studio / XML Authoring Requirements

**Document version:** 1.0  
**Status:** Normative B1 authoring baseline  
**Applies to:** CareerSpeak v1 Backend implementation  
**Scope classification:** internal B1 authoring accelerator; not a separate feature stream and not an independent MVP release gate

Normative parents:

- [`CAREERSPEAK_PRODUCT_REQUIREMENTS.md`](CAREERSPEAK_PRODUCT_REQUIREMENTS.md)
- [`CAREERSPEAK_MVP_DELIVERY_SCOPE.md`](CAREERSPEAK_MVP_DELIVERY_SCOPE.md)
- [`CAREERSPEAK_SYSTEM_REQUIREMENTS.md`](CAREERSPEAK_SYSTEM_REQUIREMENTS.md)
- [`CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md`](CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md)
- [`../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`](../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md)

Related machine contracts:

- [`../../contracts/c2-content-catalog-v3.yaml`](../../contracts/c2-content-catalog-v3.yaml)
- [`../../contracts/c4-catalogue-publication-v2.yaml`](../../contracts/c4-catalogue-publication-v2.yaml)
- [`../../contracts/learner-api-v2.yaml`](../../contracts/learner-api-v2.yaml)
- [`../../contracts/locale-configuration-v1.yaml`](../../contracts/locale-configuration-v1.yaml)
- [`../../contracts/tts-voice-catalog-v1.yaml`](../../contracts/tts-voice-catalog-v1.yaml)

---

## 1. Purpose and scope

CareerSpeak v1 already has one normative `ADMIN` actor and one secured Content Studio account. This document defines the smallest authoring surface required to populate and maintain Backend-owned catalogue/content truth quickly and safely during B1.

The Content Studio is **not** a learner application and does not change the Flutter MVP feature boundary.

Its purpose is to accelerate:

```text
catalogue maintenance
content draft editing
localization editing
bulk XML import
validation
preview / diff
safe application of changes
publication preparation
```

The v1 authoring surface SHALL prefer correctness, bulk productivity and low implementation cost over CMS breadth.

---

## 2. Architecture decision

CareerSpeak v1 Content Studio SHALL be a server-rendered Backend surface inside the Spring Boot modular monolith.

Baseline:

```text
Java 21
Spring Boot
Spring MVC
Spring Security
Spring Data JPA + Hibernate
PostgreSQL + Liquibase
Thymeleaf
HTMX 2.x
Bootstrap 5 + Tabler-compatible admin components
CodeMirror 6 for XML editing
MapStruct
Lombok with restrictions
Spring Cache + Caffeine
Jackson XML
XSD validation
StAX for bounded streaming XML parsing
```

The v1 Content Studio SHALL NOT introduce:

```text
React/Vue/Angular admin SPA
separate authoring microservice
Redis as an authoring dependency
message broker for ordinary authoring flows
remote UI schema
EAV content model
workflow/rules engine
real-time collaborative editing
```

Rationale: the authoring surface is an internal CRUD/import tool. A second SPA would increase delivery, security, build and deployment cost without improving learner acceptance.

---

## 3. Ownership and security boundary

The secured authoring boundary is:

```text
/admin/** → ADMIN session
```

V1 requires one secured Content Studio administrator account. Existing Spring Security policy owns authentication and authorization.

The Content Studio MUST NOT expose:

```text
PostgreSQL credentials
RustFS credentials
TTS Worker token
installation tokens
internal storage secrets
```

Every mutating authoring request SHALL be authenticated and CSRF-protected according to the Spring Security web session configuration.

Authoring actions SHOULD be auditable with at least:

```text
actor
operation
entity/code
source = VISUAL | XML_IMPORT
createdAt
result
```

---

## 4. Authoring model boundary

The UI SHALL NOT bind HTML/XML directly to JPA entities.

Required flow:

```text
Visual Form DTO ─┐
                 ├─→ Application Command → Service / Domain rules → JPA
XML Import DTO ──┘
```

MapStruct MAY perform structural mapping between DTOs and commands/domain projections, but domain invariants remain explicit application/domain logic.

Recommended package boundary:

```text
authoring/
  web/
  dto/
  command/
  importxml/
  diff/
  audit/

catalogue/
content/
assessment/
localization/
publication/
asset/
tts/
```

No authoring DTO becomes a persistence contract.

---

## 5. Required Content Studio UI

The v1 desktop-first shell SHOULD expose a compact navigation model:

```text
Dashboard
Catalogue
Content
Localization
Publication
Imports
```

Assessment, Assets and TTS MAY be linked from Content/Publication status views instead of receiving large standalone admin modules in the first B1 slice.

For an editable content item, the preferred surface is:

```text
┌──────────────┬─────────────────────────────────────────────┐
│ Catalogue    │ Content / collection context                │
│ tree/search  │                                             │
│              │ [Visual] [XML] [Preview] [History]          │
│              │                                             │
│              │ editable draft fields                       │
│              │ localization                                │
│              │ audio/TTS status                            │
│              │ validation                                  │
│              │                                             │
│              │          [Save draft] [Preview] [Publish*]  │
└──────────────┴─────────────────────────────────────────────┘
```

`Publish*` means invoking the existing publication/application boundary; the Content Studio does not invent an alternate publication model.

Required UX capabilities:

- searchable catalogue/content list;
- explicit current status (`DRAFT`, `READY_FOR_AUDIO`, `READY_FOR_REVIEW`, `PUBLISHED`, `ARCHIVED` where applicable);
- visual draft edit;
- XML upload by file picker and drag/drop;
- XML text editor with syntax highlighting and line numbers;
- validation errors close to the field or XML line/column when available;
- preview/diff before bulk mutation;
- clear success/failure summary;
- explicit save/apply actions; no hidden mutation during preview.

---

## 6. Content lifecycle invariants

Existing lifecycle remains normative:

```text
DRAFT
→ READY_FOR_AUDIO
→ READY_FOR_REVIEW
→ PUBLISHED
→ ARCHIVED
```

with availability:

```text
ACTIVE | INACTIVE
```

Published revisions are immutable.

Therefore:

```text
edit existing DRAFT
→ update the draft under optimistic locking

change requested for PUBLISHED revision
→ create a new DRAFT revision
→ never mutate the published revision in place
```

XML import and visual editing MUST obey the same rule.

Collection/publication references to exact published revisions MUST NOT be silently rewritten by draft editing.

---

## 7. XML authoring contract

### 7.1 Primary goal

XML exists to make large editorial changes materially faster than clicking through forms.

V1 XML import SHALL support at minimum:

```text
Vertical
LearningGoal
LearningTrack
LearningCollection
Content draft revisions
content localization
```

PracticeTest authoring MAY be added through the same importer during B1 if required for cross-system acceptance, but SHALL reuse the same validation/diff/apply pipeline rather than create a second importer.

Binary media MUST NOT be embedded in authoring XML. XML may reference stable Backend asset/audio identities where the domain permits. Object-storage credentials or direct private storage URLs are forbidden.

### 7.2 Root/versioning

The import document SHALL contain an explicit schema version, for example:

```xml
<voxprepAuthoring schemaVersion="1" mode="MERGE">
    ...
</voxprepAuthoring>
```

The XML schema is versioned independently from JPA implementation details.

Unknown schema versions fail closed.

### 7.3 Stable identity

Import matching SHALL use stable business codes/identities, not localized labels.

Examples:

```text
verticalCode
goalCode
trackCode
collectionCode
contentCode
localeCode
```

Labels are presentation values and are never identity.

### 7.4 Merge semantics

V1 default mode is `MERGE`.

Rules:

```text
present valid item     → create or update according to lifecycle rules
absent item            → unchanged
explicit inactive flag → may deactivate where domain permits
missing from XML       → MUST NOT mean delete
```

Implicit delete-by-absence is forbidden.

Hard deletion through XML is out of scope for v1. Archive/deactivate operations must be explicit and domain-valid.

---

## 8. XML import pipeline

Required production path:

```text
XML upload / editor
      ↓
request/file bounds check
      ↓
secure XML parser configuration
      ↓
XSD validation
      ↓
Jackson XML / StAX parse
      ↓
Import DTO
      ↓
semantic validation
      ↓
MapStruct / explicit command mapping
      ↓
IMPORT PLAN
      ↓
PREVIEW / DIFF
      ↓
explicit Apply
      ↓
single transactional mutation
      ↓
audit
      ↓
cache invalidation
```

Preview is read-only. No persistent domain mutation is permitted before explicit Apply.

---

## 9. XML security requirements

The importer SHALL fail closed against unsafe XML processing.

Required controls:

- DTD disabled;
- external entities disabled;
- external schema/entity resolution disabled except packaged/explicitly trusted XSD resources;
- XInclude disabled;
- secure-processing features enabled where the parser supports them;
- configurable maximum upload size; default target `10 MiB`;
- configurable maximum entity/item counts where practical;
- UTF-8 is the canonical encoding for generated/imported v1 fixtures;
- parser errors must not leak server filesystem paths or credentials;
- XML extension/MIME checks are advisory only; actual parsing/validation is authoritative.

XXE payloads MUST be rejected by acceptance tests.

For large accepted files, StAX/streaming parsing SHALL be preferred over building a full DOM tree. The implementation may reject files beyond safe configured limits rather than permit unbounded memory use.

---

## 10. Validation model

Validation occurs in layers:

```text
L1 XML well-formedness
L2 XSD structural validation
L3 field validation
L4 reference/ownership validation
L5 lifecycle validation
L6 publication/exact-revision validation where relevant
```

Representative semantic failures:

```text
Goal references unknown Vertical
Track references wrong Goal
Collection references wrong Track
duplicate stable code in one import
unsupported locale
invalid lifecycle transition
attempt to mutate PUBLISHED revision
unknown asset/TTS reference where required
```

Any blocking `ERROR` prevents Apply.

Warnings MAY permit Apply only when they do not weaken domain correctness.

---

## 11. Preview / diff contract

Every XML import MUST produce an explicit dry-run plan before Apply.

Diff categories:

```text
CREATE
UPDATE_DRAFT
CREATE_REVISION
ACTIVATE / DEACTIVATE where permitted
NO_CHANGE
WARNING
ERROR
```

There is no implicit `DELETE` category in v1 XML import.

Example summary:

```text
XML IMPORT PREVIEW

CREATE            24
UPDATE_DRAFT       7
CREATE_REVISION    3
NO_CHANGE         91
WARNING            1
ERROR              0
```

The operator must be able to inspect entity/code-level details before Apply.

For a requested change to a published content revision, the diff MUST show `CREATE_REVISION`, not `UPDATE`.

---

## 12. Preview consistency and stale-plan protection

Preview and Apply are two different requests but one logical operation.

The server SHALL derive a preview identity from at least:

```text
source SHA-256
schemaVersion
normalized import plan fingerprint
relevant current baseline/version fingerprint
```

Apply MUST fail closed and require a new preview when the authoritative baseline changed in a way that invalidates the preview.

This prevents:

```text
preview old state
→ another edit occurs
→ apply stale assumptions
```

No client-supplied diff is trusted as the mutation source; the Backend remains authoritative.

---

## 13. Transaction and rollback semantics

V1 Apply is atomic for one accepted import unit.

```text
all planned metadata mutations succeed
→ COMMIT

any blocking persistence/domain failure
→ ROLLBACK
```

Partial-success persistence is forbidden for v1 bulk import.

If a file is too large for a safe atomic import, the operator must split it or use a future explicitly designed batch mechanism; the system SHALL NOT silently degrade into partial commits.

Optimistic locking (`@Version` or equivalent) SHALL protect mutable draft entities against lost updates.

---

## 14. Idempotency and auditability

The importer SHALL calculate a SHA-256 hash of the accepted source bytes.

Repeated submission of an identical source against an unchanged baseline SHOULD resolve deterministically to the same preview and SHOULD produce `NO_CHANGE` after a successful previous Apply.

At minimum persist/import-log:

```text
importId
sourceSha256
schemaVersion
actor
createdAt
status
summary counts
error summary when failed
```

Raw XML retention is optional and must follow storage/security policy; the hash and deterministic result are mandatory enough for v1 traceability.

---

## 15. MapStruct rules

MapStruct is the default compile-time mapper for repetitive structural mappings.

Recommended usage:

```text
Form DTO → Application Command
XML DTO  → Import Command / normalized input
Domain   → View DTO
```

Rules:

- `componentModel = "spring"`;
- unmapped target fields SHOULD fail compilation for critical mappers (`ReportingPolicy.ERROR`);
- lifecycle transitions, identity allocation and reference validation MUST NOT be hidden inside generated mapping;
- mapping code must not issue repository/network calls;
- mapper tests cover custom conversions and update semantics.

MapStruct exists to remove boilerplate, not to become the domain layer.

---

## 16. Lombok rules

Lombok may be used for non-domain boilerplate where it improves readability.

Allowed examples:

```text
@Getter
@Setter on mutable form/import DTOs where needed
@Builder
@RequiredArgsConstructor
@NoArgsConstructor where required by JPA/Jackson
```

`@Data` SHALL NOT be used on JPA entities.

JPA entity `equals/hashCode/toString` behavior must be deliberate and must not accidentally traverse lazy relations.

Java records SHOULD be preferred for immutable commands/results when they fit framework constraints.

When Lombok and MapStruct are used together, the build SHALL configure the compatible annotation-processor ordering/binding explicitly.

---

## 17. Caffeine cache policy

Spring Cache + Caffeine is permitted only for bounded read-mostly Backend data where stale draft state is not acceptable.

Good candidates:

```text
publishedCatalogue
supportedLocales
ttsVoiceCatalogue
category/level/skill reference data
publication metadata projections
```

Do NOT cache as shared authoring truth:

```text
current editable draft
unsaved form state
XML import session source
preview/diff authority
open transaction state
```

Correctness rule:

```text
Apply / Publish affecting cached read models
→ explicit cache eviction/invalidation
→ next read rebuilds authoritative projection
```

TTL is a safety bound, not the correctness mechanism.

The Content Studio SHALL remain correct with Caffeine disabled.

---

## 18. Visual editor behavior

The visual editor and XML importer SHALL converge on the same application/domain commands and invariants.

Required visual editing behavior:

- edit only mutable draft state;
- show stable code separately from localized labels;
- show parent ownership context;
- validate before save;
- detect optimistic-lock conflict;
- never overwrite another edit silently;
- present lifecycle/status clearly;
- provide direct access to XML/import preview where bulk changes are faster.

CodeMirror XML editing is an accelerator, not a separate source of truth. Saving XML always uses the import pipeline.

---

## 19. Publication boundary

The Content Studio may initiate/prepare publication but SHALL NOT bypass C4 Atomic Publication.

Required boundary:

```text
Authoring DRAFT/READY state
→ existing publication validation
→ exact immutable publication candidate
→ atomic CURRENT activation
```

A successful XML import does **not** automatically make content learner-visible.

Learner-deliverable remains:

```text
PUBLISHED + ACTIVE
```

through the accepted publication contract.

---

## 20. Failure behavior

The UI must distinguish at least:

```text
XML parse error
XSD error
semantic validation error
stale preview
optimistic locking conflict
transaction/apply failure
publication validation failure
```

Failures must provide an operator-safe explanation and corrective action where practical.

Raw stack traces, SQL errors, filesystem paths, storage secrets and credentials are never rendered to the browser.

A failed Apply leaves authoritative data unchanged.

---

## 21. Testing requirements

Minimum automated coverage for this authoring slice:

```text
unit:
  XML DTO parsing
  semantic validators
  diff planner
  custom MapStruct conversions
  lifecycle mapping rules

integration:
  MVC security
  XSD validation
  repository-backed preview
  atomic apply/rollback
  optimistic locking
  cache invalidation
  published-revision immutability

security/adversarial:
  XXE
  DTD/external entity
  malformed XML
  oversized input
  duplicate codes
  dangling refs
  wrong-parent hierarchy
  stale preview
  replay identical import
```

Representative XML fixtures SHALL be committed with expected preview summaries.

---

## 22. Acceptance criteria

Content Studio v1/B1 authoring acceptance requires all of the following:

```text
A01 /admin authoring surface is ADMIN-only and CSRF-protected
A02 visual editor can create/update valid mutable drafts without binding directly to JPA entities
A03 valid XML can be uploaded/pasted and validated without mutating persistent domain state
A04 malformed/XSD-invalid XML is blocked with useful location/error information where available
A05 semantic dangling/wrong-parent references block Apply
A06 preview exposes CREATE/UPDATE_DRAFT/CREATE_REVISION/NO_CHANGE/WARNING/ERROR details
A07 changing a PUBLISHED content revision creates a new DRAFT revision; published data remains immutable
A08 absence from MERGE XML never implies deletion
A09 stale preview/baseline mismatch blocks Apply and requires re-preview
A10 Apply is atomic; injected failure rolls back the complete import unit
A11 identical replay against unchanged state is deterministic and does not duplicate domain objects
A12 optimistic locking prevents silent lost updates between editors/imports
A13 successful Apply/Publish explicitly invalidates affected Caffeine read caches
A14 correctness is preserved with Caffeine disabled
A15 XXE/DTD/external-entity attack fixtures are rejected
A16 visual and XML paths converge on the same application/domain invariants
A17 XML import does not bypass C4 publication or make DRAFT content learner-visible
```

This acceptance is subordinate to B1/A1. It does not create a sixth MVP delivery stage.

---

## 23. Implementation sequence

To maximize time-to-content, implementation order SHALL be intentionally small:

```text
B1-A0  secure /admin shell + Thymeleaf/HTMX baseline
  ↓
B1-A1  XML schema + secure parser + XSD/semantic validation
  ↓
B1-A2  deterministic import plan + Preview/Diff
  ↓
B1-A3  transactional Apply + lifecycle/revision rules + audit
  ↓
B1-A4  compact visual draft editor using the same commands
  ↓
B1-A5  Caffeine read caches + explicit invalidation + adversarial acceptance
```

Do not delay XML bulk authoring until after a large visual CMS is built. The XML path is the primary productivity accelerator for initial catalogue/content population.

---

## 24. Explicit v1 non-goals

The following are not required for CareerSpeak v1 Content Studio:

```text
multi-tenant CMS
multiple editorial roles/approval matrix
real-time collaborative editing
WYSIWYG page builder
generic workflow engine
generic EAV schema
React/Vue/Angular admin SPA
arbitrary XSLT execution
implicit delete-by-absence
partial-success bulk import
direct RustFS browser credentials
learner account management
analytics dashboard
```

A future need must be introduced through a separate versioned requirement after MVP evidence exists.

---

## 25. Architecture summary

```text
                    CONTENT STUDIO

        Visual editor             XML editor/upload
             │                           │
             └─────────────┬─────────────┘
                           ↓
                  DTO / import model
                           ↓
             XSD + semantic validation
                           ↓
                 deterministic plan
                           ↓
                    Preview / Diff
                           ↓
                  explicit Apply
                           ↓
              application/domain rules
                           ↓
              PostgreSQL transaction
                           ↓
                    audit + cache
                       invalidation
                           ↓
                  publication flow
                           ↓
                    C4 CURRENT
                           ↓
                     Learner API
```

The design goal is deliberately narrow: **fast editorial throughput without weakening revision, publication, security or cross-system invariants**.
