# A2 — CLOSED for API-02 through API-06

Qualified source SHA: `26e9cafc2590c02b85cf27fe8ff63bf97cc709b1`.
Execution: actual macOS 15.6 arm64, 2026-11-05 21:47–21:49 Asia/Almaty.
Backend: Java 21.0.10, Spring Boot 4.1.2, DEV HTTP `127.0.0.1:18081`.
Existing A1 PostgreSQL/RustFS containers and volumes were preserved throughout A2.

| Gate | Result | Real evidence |
|---|---|---|
| API-02 | PASS | Anonymous MVC redirects to login; real password login rotates session ID; direct login lands on /admin, saved-request login returns to editor; CSRF-less mutation returns 403 without DB changes; editor and picker screenshots |
| API-03 | PASS | Template/XSD downloaded by HTTP; mixed valid+invalid XML rejected without partial writes; import before validation and changed-file import rejected; original validated XML imported as one DRAFT |
| API-04 | PASS | Imported DRAFT edited by MVC; PNG uploaded to real backend storage, preview bytes verified, bound by MVC; READY_FOR_AUDIO → READY_FOR_REVIEW → APPROVED → exact candidate validation → PUBLISHED |
| API-05 | PASS | Registered learner installation, protected manifest rejects unauthenticated HTTP; CURRENT v3 root, canonical packs, six catalogues and exact phrase payload served by HTTP with matching revisions/checksums |
| API-06 | PASS | Read-only PostgreSQL queries match release/CURRENT, frozen wire JSON and checksums, exact content identity and published lifecycle; ROOT/PACK/CATALOGUE canonical hashes independently reproduced |

## Reproduction

With the existing backend running:

```bash
./scripts/local/qualify-studio.sh
```

Final execution exited **0** and recorded **87 HTTP/SQL operations** in
`artifacts/local-smoke/a2-20261105T164711Z/report.json`. Every operation records
its HTTP status or subprocess exit code, timestamp, path or SQL, and body evidence.
The initial runner result explicitly waits for visual evidence; the supplement
`qualification.json` completes API-02 with verified browser screenshots and hashes.

All authoring, media binding and publication use production HTTP/MVC operations.
SQL in this runner is limited to SELECT. Credentials, cookies, CSRF and installation
tokens remain in memory; HTML evidence redacts CSRF values. A run adds a unique
fixture and advances CURRENT through the publisher; it does not erase prior
releases or reset any database/volume. Existing PUBLISHED refs are retained in
subsequent qualification releases.

For a stopped backend, run `./scripts/local/backend-start.sh` (foreground).
Default local HTTP port is 18081, because another application occupies 18080.
Use `VOXPREP_LOCAL_BACKEND_PORT` consistently for startup and the HTTP runner.

## Exact identities and hashes

| Item | Value |
|---|---|
| Content | `A2_PHRASE_464EE429F0`, type phrase, exact revision 1 |
| Revision UUID | `26542816-6acb-4131-9e25-f4eeab49efd4` |
| Candidate UUID | `d376731d-41bc-4d9b-80ea-a87e64ae2895` |
| Release UUID | `1174da15-4ff8-47ae-abec-200e967ce08e`, contentVersion 3 |
| Legacy candidate-ref SHA | `30202f2f34e61e494cb8b251fdd34bd2e1220b434871e9a5e0378723b43f5462` |
| Immutable Flutter ROOT wire SHA | `282cfc16835036959d8ba11b007de9387eb6f5ded02556a59dbf999d0c71b66a` |
| Exact content checksum | `04c12a0f9e461ef6ff7e443e0c41fc865f5e969dbc8af8453f1699211ad82787` |
| report.json file SHA-256 | `59a5385cbfeff56b1cc4e73ed3f19733822ff06292f40c40c5a70ea9d36281f6` |
| qualification.json file SHA-256 | `04d03a9c9cc6c2f5c25132d5f4b146c6022f790c1acce684c2404dd0123cc37b` |

The HTTP root body checksum and ETag match the checksum stored for the immutable
ROOT wire document, with equal decoded HTTP/DB JSON. The ROOT canonical projection
excludes its own checksum field; raw response/file SHA-256 is a separate value.
The publication release/candidate hash is the legacy exact-ref hash and is
deliberately **not** substituted for the Flutter ROOT checksum.

## Shared media selection and regression fixes

Vertical create/edit uses a hidden asset UUID populated by the Media Library,
with selected-image preview. Cover/content image controls use the same dialog,
upload, compatible READY-image list and selection cards. The role determines
which images can be used. No operator needs to type or copy a UUID.

Browser verification confirmed both unsaved vertical fields and an unsaved DRAFT
title survive selection. DRAFT binding updates the preview/confirmation without
reloading the page. The supplementary DRAFT used for that UI check is
`10731f91-de32-4f22-819a-0731d04caa43`; its unsaved test title was not submitted.

Screenshots in the final evidence directory:

- `media-picker.jpg`, `icon-selected.jpg` — selection and preserved vertical form.
- `content-selection-preserved.jpg` — DRAFT title preserved after real binding.
- `published-editor.jpg` — exact revision PUBLISHED with read-only fields.
- `publication.jpg` — CURRENT v3 and published candidate.

An earlier negative-image run exposed HTTP 500 for a false PNG signature. The
controller now returns safe HTTP 400, without leaking exception details; the final
live run verifies no partial asset/content state. Targeted regression command:

```bash
source scripts/local/java-env.sh
mvn -B -ntp -f backend/pom.xml -Dtest=MediaPickerControllerTest test
```

Result: **1 test, 0 failures/errors/skips**, exit 0. Log:
`artifacts/local-smoke/a2-bootstrap/media-picker-test.log`.
The direct-login 404 was fixed with `/admin` as the fallback success destination,
preserving Spring Security saved-request behavior.

## Remaining scope

Drift persistence/offline reopen belongs to A4 and is NOT RUN. Piper/audio belongs
to A3 and is NOT RUN; the published phrase reports hasAudio=false. Full backend
verify and readiness/liveness outage injection are not claimed by this milestone.
A5 and full-stack acceptance remain NOT ACCEPTED. This report qualifies the SHA
above; later application changes require a new run. No merge to main performed.
