# MVC-R8 XML template and dry-run validator (first slice)

Status: code implemented in Draft PR #49; exact-SHA CI and browser verification required.
**This is not a bulk import implementation.** It does not write to PostgreSQL, RustFS, publication or any catalogue. No content lifecycle is bypassed.

## ADMIN MVC endpoints

- `GET /admin/imports`: upload/validation UI with links to examples and XSD
- `GET /admin/imports/template.xml`: versioned example XML, Content-Disposition attachment
- `GET /admin/imports/schema.xsd`: versioned XSD, Content-Disposition attachment
- `POST /admin/imports/validate`: multipart field `file`, CSRF required, read-only dry-run

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
- A successful result means the file passes this initial XML validation, **not** that referenced Question revisions exist in the database or that a DRAFT can already be created.

## Safety limits

- Maximum input: 1 MiB, up to 100 records per file, bounded issue list.
- XML DTD and external entities disabled, external schema access disabled; parser and schema use secure processing.
- Server-side XML is never echoed raw into the page; Thymeleaf escapes rendered values.
- Only ADMIN routes; multipart POST requires CSRF.
- No external XML network access and no execution of user-supplied instructions.

## Acceptance and next step

1. Confirm template validates and XSD downloads; XXE and malformed documents fail.
2. Verify role boundary, CSRF, size limit and zero database writes.
3. Implement domain DTO mapping to `ContentDraftUpdate` for all seven types; validate existing codes and question references against DB, use `ContentAuthoringService.createInitialRevision` in bounded atomic batches.
4. Add idempotency/duplicate policy, explicit approval-free DRAFT creation, import job/report and rollback tests.
5. No publishing via import: editorial review/TTS/approval/publication remain mandatory.

See `backend/src/test/java/io/github/alimbetov/voxprep/backend/content/application/ContentXmlDryRunServiceTest.java` and `.../content/web/ContentXmlImportMvcIntegrationTest.java`.
