# MVC-R8 XML template and dry-run validator (first slice)

Status: XML validation and transactional DRAFT import implemented in Draft PR #49; exact-SHA CI and browser acceptance pending. No approval, RustFS write, publication or catalogue change is performed.

## ADMIN MVC endpoints

- `GET /admin/imports`: upload/validation UI with links to examples and XSD
- `GET /admin/imports/template.xml`: versioned example XML, Content-Disposition attachment
- `GET /admin/imports/schema.xsd`: versioned XSD, Content-Disposition attachment
- `POST /admin/imports/validate`: multipart field `file`, CSRF required, read-only dry-run
- `POST /admin/imports/import-drafts`: multipart field `file`, CSRF required; available only after successful dry-run of byte-identical XML within 10 minutes; all-or-nothing PostgreSQL DRAFT creation

## XML format

- Root: `<voxprep schemaVersion="1">`
- Each record: `<content code="MY_CODE" type="phrase">`, with metadata fields `title`, `subtitle`, `description`, `categoryCode`, `levelCode`, `minutes`, `availability` and repeated `skill`.
- A single `<body>` contains type-specific fields:
  - `phrase`: `phrase`, `usage`, optional repeated `example`
  - `vocabulary`: `term`, `definition`, optional `partOfSpeech` and `example`
  - `interview`: `prompt`, `modelAnswer`, optional `keyPoint`
  - `topic`: repeated `<section><heading>...</heading><text>...</text></section>`
  - `shadowing`: `transcript`, repeated `<segment startMs="0" endMs="1000">text</segment>`
  - `question`: `questionText`, optional `explanation`, repeated `<option key="A" correct="true">text</option>`
  - `practice_test`: `instructions`, `passingScorePercent`, repeated `questionRevisionId` (UUID)
- This v1 XSD covers the metadata structure and supported types; application semantic validation adds per-type requirements, option uniqueness/correctness, timestamp order, and UUID checks.
- A successful dry-run means the file passes initial XML validation, **not** that referenced Question revisions exist in the database; database reference validation occurs during import preflight. The included Practice Test example has an intentionally unresolved placeholder UUID and therefore must be removed or corrected before importing.

## Safety limits

- Maximum input: 1 MiB, up to 100 records per file, bounded issue list.
- XML DTD and external entities disabled, external schema access disabled; parser and schema use secure processing.
- Server-side XML is never echoed raw into the page; Thymeleaf escapes rendered values.
- Only ADMIN routes; multipart POST requires CSRF.
- No external XML network access and no execution of user-supplied instructions.
- Re-upload must match the SHA-256 from the current HTTP session; expired or changed files are rejected.
- Preflight checks existing revision-1 identity/checksum, collisions, and Practice Test references to approved/published Question revisions; no partial commits. Identical existing DRAFTs are skipped; conflicting or immutable revisions cause a full rollback.
- Per-code PostgreSQL advisory transaction locks are acquired in sorted order for concurrent import batches.
- Category/level/skill codes are validated by existing code syntax rules; no separate catalogue lookup service exists for these metadata codes. Validation of their existence is **not** claimed.

## DRAFT import acceptance (implemented, pending CI)

1. Validate XML and choose the same file again for DRAFT import. The validation marker is scoped to the admin HTTP session, SHA-256 and a 10-minute expiry.
2. The backend reruns XML validation and converts all seven content-body representations through the existing MVC mapper.
3. The authoring service creates revision-1 DRAFTs transactionally. Duplicate identical DRAFTs are not re-created; conflicting existing records abort the batch.
4. Practice Test question references must already exist as APPROVED or PUBLISHED Question revisions. XML template placeholder will fail this preflight intentionally.
5. The import cannot transition to READY_FOR_AUDIO, APPROVED or PUBLISHED.

## Remaining hardening

- Verify exact-SHA B1 + complete CI, then use a real admin browser to test XML download/validate/import.
- Extend structured XSD with strict per-body schema, nested cardinality and error line/column.
- Add a persisted import ledger/report for cross-session idempotency audit, and operator-friendly reason codes.
- Consider JSON/CSV only after XML atomic acceptance is demonstrated.

## Acceptance and next step

1. Confirm template validates and XSD downloads; XXE and malformed documents fail.
2. Verify role boundary, CSRF, size limit and zero database writes.
3. Implement domain DTO mapping to `ContentDraftUpdate` for all seven types; validate existing codes and question references against DB, use `ContentAuthoringService.createInitialRevision` in bounded atomic batches.
4. Add idempotency/duplicate policy, explicit approval-free DRAFT creation, import job/report and rollback tests.
5. No publishing via import: editorial review/TTS/approval/publication remain mandatory.

See `backend/src/test/java/io/github/alimbetov/voxprep/backend/content/application/ContentXmlDryRunServiceTest.java` and `.../content/web/ContentXmlImportMvcIntegrationTest.java`.
