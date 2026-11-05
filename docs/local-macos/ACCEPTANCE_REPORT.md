# Local Mac acceptance — A1 milestone

This section preserves the original A1 qualification. Current A2 results are in
[A2_ACCEPTANCE.md](A2_ACCEPTANCE.md): API-02–API-06 PASS on that report's SHA.
The NOT RUN A2 rows below describe the earlier A1 milestone only.

Date: 2026-11-05, 21:26 Asia/Almaty (16:26 UTC).
Host: macOS 15.6 / arm64. Qualified source SHA:
`1faaeb55240937288b5dad2695fc9a3fb519a73b` (clean checkout).
Decision: **A1 PASS; full-stack NOT ACCEPTED**. A2 has migration/startup evidence,
but its Content Studio/publication scenarios are NOT RUN.

## Executed gates

| ID | Result | Evidence |
|---|---|---|
| INF-01 | PASS | Compose healthy and pg_isready succeeds |
| INF-02 | PASS | TCP password authentication as voxprep_backend; SQL assertion returns 1 |
| INF-03 | PASS | 50 Liquibase changesets present; app/liquibase table owners are voxprep_migrator or voxprep_owner; runtime CREATE/ALTER and Liquibase read/ALTER fail with SQLSTATE 42501 |
| INF-04 | PASS | RustFS readiness HTTP succeeds, ready=true |
| INF-05 | PASS | SigV4 backend IAM PUT/GET, byte and SHA-256 comparison; DELETE succeeds and subsequent GET returns 404 |
| INF-06 | PASS | Migrator-created unique test row and backend-IAM S3 object survive restart of only VoxPrep postgres/rustfs; same value/bytes/hash after health recovery |
| API-01 | PASS | HTTP 200, status UP for both liveness and readiness on 18081 after infrastructure restart |
| API-02–API-06 | NOT RUN | Content Studio/auth/XML/publication/HTTP consistency not qualified |
| TTS-01–TTS-06 | NOT RUN | Worker not started |
| FLT-01–FLT-06 | NOT RUN | Flutter not started |

US-01–US-06: NOT RUN. Backend full unit/verify suite, Worker pytest and Flutter
analyze/test: NOT RUN. A1 uses real PostgreSQL/RustFS with no mock storage or H2.
Failure checks cover schema permissions; readiness degradation during an outage
was not sampled and remains an A2 task.

## Commands and results

`./scripts/local/qualify-infra.sh --migrations` exited **0** at 16:26 UTC.
Its `report.json` records every command, SQL stdin, timestamp, exit code, expected
SQLSTATE denial, HTTP status and image digest. SQL negative commands exit **3**
as expected. SQL checks run in transactions, so even unexpected permission grants
cannot leave a forbidden schema change committed. Only a unique test table is
created/dropped; no publication business data is inserted directly.

`./scripts/local/smoke-backend.sh` exited **0** at
`2026-11-05T16:26:48.968544+00:00`, on the same SHA. Both health URLs return UP.
Backend is Java 21.0.10 / Spring Boot 4.1.2, DEV profile, JDBC port 55432, S3 port
19000 and HTTP port 18081. Port 18080 belongs to another application.

Initial backend startup applied all 50 changesets successfully using the existing
migrator config; subsequent startup reported an up-to-date database. Runtime uses
the existing separate datasource identity. Original startup log:
`artifacts/local-smoke/a1-20261105T162417Z/backend.log`; repeat-start log:
`artifacts/local-smoke/a1-20261105T162528Z/backend.log`. These earlier logs are
supporting migration evidence, not the final A1 exact-SHA run.

Final local evidence directory: `artifacts/local-smoke/a1-20261105T162625Z/`.
Runtime evidence remains gitignored, separate from this versioned summary.

| Item | SHA-256 |
|---|---|
| Test payload, before and after restart | `1c2a57726ad60377b1d771f2fbe18afdd054130ee485c9418f9655a77c796c6e` |
| report.json | `d7f2bd9d5ca359cb59ca0f4c730ab71bf893d2c45783c0c274f201285fb84958` |
| health.json | `239bda8c909001d9f27a070fe8d07bfe7a7bc5170e7231b5c8c32c0aabbb1b33` |

Images executed as linux/arm64:

- PostgreSQL: `postgres@sha256:f1ea2a1a4fb7b68d4836be1fdcb8a6466a89b072158bf9d97663600538c294c5`.
- RustFS: `rustfs/rustfs@sha256:ed9210d6411d77ffceb70d94b964a3cb7d225983368bc25bebe01e995293dcc2`.

The test runs `docker compose restart --timeout 30 postgres rustfs`, then bounded
health waiting. It never runs `down -v`. Test object deletion and unique test table
cleanup succeeded. Existing containers and volumes from other projects were not
modified. Root S3 credentials were used only by the earlier bootstrap, never by
the qualification client. Re-run the commands after any implementation change;
this report certifies the SHA above, not future revisions.
