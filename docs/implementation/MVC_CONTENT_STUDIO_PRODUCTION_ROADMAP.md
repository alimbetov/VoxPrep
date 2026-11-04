# MVC Content Studio production roadmap (R5 follow-up)

Status: MVC-R5 Practice Test question selector implemented; MVC-R6 real-job status, generation command and verified MP3-preview implemented; exact-head CI and real audio acceptance pending; NOT release accepted.
Branch: feat/r5-commercial-chain-qualification. R5 store gates remain independent and mandatory.

## Existing guarantees

- Spring MVC + Thymeleaf + Bootstrap/HTMX, authenticated ADMIN and CSRF.
- Catalogue: Vertical → Goal → Track → Collection. Collection FREE/FULL is the sole learner-access rule.
- Seven content body types: phrase, vocabulary, interview, topic, shadowing, question, practice_test.
- Draft-only updates, review/approval, next immutable revision; media and localization bindings.
- Publication candidate validation/freeze and atomic CURRENT activation.

## Delivered initial UX slice (requires CI/device validation)

1. Replace access select with explicit FREE / $ FULL radio labels in collection MVC form.
2. Add access badges in catalogue list, using String CatalogueSnapshot.accessLevel().
3. Initial-revision MVC form shows only fields for selected content type; on type change nonmatching inputs are disabled so stale cross-type fields are not posted. JavaScript-free fallback must remain safe through backend body-type validation.
4. No schema/API/entitlement policy changes.

## MVC-R5 first implementation slice

- Row-based add/remove/reorder progressive editor wired to examples, interview key points, topic sections, shadowing segments and question options. Existing newline/pipe wire format is retained; malformed legacy field input stays editable as raw textarea.
- Collection membership UI now uses bounded, title-searchable APPROVED/PUBLISHED revision picker instead of typed UUID. Server still revalidates eligibility, identity, and revision ordering.
- This does not yet include the Practice Test question picker, catalogue drag-and-drop, or a complete production-grade repeating form builder.
- New HTTP/DB tests validate initial form rendering, role boundary and approved query; still require exact-SHA CI.

## MVC-R5 Practice Test picker (implemented, pending qualification)

- New admin-only `GET /admin/content/questions/approved?q=&page=` reads APPROVED/PUBLISHED Question exact revisions using a bounded, type-filtered repository query.
- Practice Test create/edit forms offer searchable question selection, ordering and removal while preserving `questionRevisionIds` newline UUID contract to server.
- Current selection survives failed requests; non-JavaScript fallback retains native textarea. Draft or non-Question revisions cannot be supplied as selectable options; existing domain validation remains source-authoritative.
- HTTP tests assert non-admin rejection and that DRAFT questions are excluded.

## MVC-R6 first read-only TTS slice (implemented, pending qualification)

- Editor embeds existing revision-scoped TTS jobs (role, language, model, attempts, status, failure code) rather than mock records.
- READY audio preview `GET /admin/content/revisions/{revisionId}/tts/jobs/{jobId}/preview` verifies exact revision ownership, TTS_AUDIO kind, READY job/asset state, audio/mpeg and media size/hash through LearnerMediaService. Never exposes RustFS keys or Worker access.
- The content editor offers role and ACTIVE voice model selection for READY_FOR_AUDIO content. POST /admin/content/revisions/{revisionId}/tts/prepare delegates to existing TtsJobPreparationService, preserving advisory-locked fingerprint idempotency, immutable job/file identities and backend-owned TTS lifecycle. Identical fingerprint returns existing job; altered model/revision gives new job. Session auth + CSRF apply.
- No forced regeneration of identical fingerprint, no Worker direct call, no mutating APPROVED or PUBLISHED revisions.
- Remaining: real Piper→RustFS→MVC playback acceptance, failure/retry UX, concurrency qualification, detailed QC and business approval integration.

## Work remaining (NOT implemented)

### MVC-R5 — editor usability and structured form builder
- Add accessible repeating form rows with add/remove/reorder for Topic heading/text, Question options, Interview key points, vocabulary examples, shadowing segments and Practice Test question selection.
- Keep server authoritative for body schemas, numeric ranges and unique option keys; support server redisplay of invalid forms without lost data.
- Use catalogue-backed selectors where stable codes exist; fall back to explicit code when catalog data unavailable.
- Acceptance: each of 7 types can be created, edited, validated and resubmitted on real authenticated HTTP; invalid body rejected; immutable approved revision never edited.
- Add tests for JavaScript-assisted and no-JavaScript fallback and accessibility.

### MVC-R6 — TTS operations and review
- Read-only audio job status, exact model/voice, error and latest asset metadata.
- Authorized synthesis/retry/regenerate commands through existing backend application services; no direct Worker or RustFS client calls from MVC.
- Stream actual approved preview audio through authenticated Backend; compare source text, pronunciation notes, revisions, checksum and duration.
- Acceptance: real Piper job PENDING → RUNNING → READY, hearing actual MP3, replay/stale lease rejected, approval guarded against missing required audio.

### MVC-R7 — truthful Flutter preview
- Implement typed read-only preview based on exact published/approved payloads for ALL seven content types, including locale and media permissions.
- Preview must not silently invent mobile features; ideally share fixture contract snapshots tested against production Flutter renderer/widget tests.
- Show FREE/FULL lock states inherited only from collection membership.
- Acceptance: real device/screenshots and rendered widget tests prove no mismatch for all types, empty/invalid assets and long text.

### MVC-R8 — bulk content import
- Versioned XML/JSON/CSV schemas; restrictive XML parser (XXE disabled), source size/row limits, explicit encoding, sanitized preview, dry-run and per-row validation report.
- Import atomic per controlled batch through existing authoring applications. Idempotency key and duplicate code policy; no direct SQL writes.
- No automatic publish from import. Imported data begins DRAFT and goes through regular review.
- Acceptance: duplicate replay, failure halfway, corruption, unsupported version, 10k-row bounds, concurrent import, zero side effects on dry-run.

### MVC-R9 — editor productivity
- Search/filter by vertical, collection, type, lifecycle, availability, locale, TTS status; stable pagination.
- Copy-to-new-DRAFT, templates, bulk operations respecting authorization and expectedVersion.
- Replace raw UUID input in collection membership and test questions with searchable approved-revision selector; persist exact IDs.
- Catalogue visual hierarchy first; any drag-and-drop order change must be validated and persisted atomically, with keyboard-accessible reorder.
- Localized original-vs-translation diff; revision-to-revision diff.

### MVC-R10 — authoring QA and publication readiness
- Per-content checklist of required fields, locale completeness, audio, image licenses/provenance, test keys, publication bindings, and FREE/FULL access leak protection.
- Release candidate composition through approved revision selector rather than manual code|type|revision|checksum entry.
- Show blocking validation and exact root SHA; preserve immutable published manifests and N→N+1 Flutter compatibility.
- CI + device E2E over ADMIN HTTP → Postgres/RustFS → publication → Flutter/Drift offline; do not count mocked Store as real acceptance.

## Release sequencing
- Keep PR Draft until exact-head required CI passes.
- R5 remains gated on real Google Play / Apple sandbox purchase, restore, revoke and written offline entitlement rules.
- Prioritize full learner rendering of seven content types before building bulk import; avoid producing material Flutter does not show.
- Never mark a phase CLOSED from documentation or code presence alone; require exact SHA and independent acceptance evidence.
