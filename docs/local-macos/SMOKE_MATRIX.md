# VoxPrep local full-stack smoke matrix

All scenarios are **NOT RUN** until executed on the user's actual MacBook. Status vocabulary: `PASS`, `FAIL`, `BLOCKED`, `NOT RUN`. Each test record must contain exact git SHA, platform, timestamp, invocation, exit code and reproducible evidence location.

| ID | Check | Passing evidence |
|---|---|---|
| INF-01 | PostgreSQL healthy | Compose healthy + pg_isready |
| INF-02 | Authenticated SELECT 1 | SQL output and exit code 0 |
| INF-03 | Runtime vs migration privileges | expected access denials and migration success |
| INF-04 | RustFS READY | health/ready status 200 |
| INF-05 | S3 PUT/GET/DELETE with Backend IAM | object checksum and deletion verification |
| INF-06 | Persistent storage restart | state/hash preserved across restart |
| API-01 | Backend readiness | actual Actuator readiness UP |
| API-02 | Authenticated Content Studio | real MVC session page/status and screenshot |
| API-03 | XML template and validator | valid accepted, invalid rejected safely |
| API-04 | Draft → approve → publish | committed revision and entity IDs |
| API-05 | CURRENT manifest/payload HTTP | HTTP 200, revision and response hashes |
| API-06 | DB/HTTP/Drift publication hashes | consistent revision, content hash, persisted local proof |
| TTS-01 | Worker authenticates to backend | authorized claim poll, no secret leak |
| TTS-02 | Real exact model SHA | ONNX and config checksums |
| TTS-03 | PENDING to READY job | timestamps, lease and job ID |
| TTS-04 | Real MP3 audio quality | ffprobe codec, mono, 24k, 60–68 kbps |
| TTS-05 | RustFS durable MP3 | backend asset reference + object hash |
| TTS-06 | Replay/lease recovery | negative and retry assertions |
| FLT-01 | Flutter real app starts | target, flutter command, screenshot |
| FLT-02 | HTTP live catalogue | real request/decoder evidence |
| FLT-03 | Persisted Drift material | SQLite/Drift state assertion |
| FLT-04 | Cold offline reopen | no network, material displayed after process restart |
| FLT-05 | CURRENT N→N+1 + failure retry | atomic consistency and corrupted payload recovery |
| FLT-06 | FREE/FULL and MP3 behavior | access assertions + playback proof if implemented |

## Beyond the 24 gates

Mandatory **user-story cross-service acceptance**: US-01..US-06 from `A5_E2E_ACCEPTANCE.md`, including Content Studio XML/photo flow, TTS MP3 preview, failure recovery and no silent mock adapters.

## Acceptance report template

```markdown
# Local Mac Acceptance
Target: macOS <version>, <arm64|x86_64>
Git SHA: <exact SHA>
Date/time: <ISO8601>
Execution host: <identifier without personal data>
Status: NOT ACCEPTED

| ID | Status | Command | Exit | Evidence | Notes |
|---|---|---|---|---|---|
| INF-01 | NOT RUN | ... | ... | ... | ... |
... all 24 rows ...

User stories US-01..US-06: <status and evidence>
Failure injections: <status and evidence>
Backend unit/verify: <exit/status>
Worker pytest: <exit/status>
Flutter analyze/test: <exit/status>
Outstanding BLOCKED: <root causes>
Final decision: ACCEPTED only if mandatory checks pass at exact SHA.
```

## Operating safety

No production store credentials, customer data or Apple/Google real payments in local smoke. No destructive cleanup. Redact tokens, passwords, signed S3 URLs and private identifiers from evidence.
