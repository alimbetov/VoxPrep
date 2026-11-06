# VoxPrep — local macOS full-stack acceptance

**Purpose:** reproducible real local execution on a MacBook: PostgreSQL + RustFS + Spring Boot + Piper TTS Worker + Flutter, with exact-SHA end-to-end evidence.

**Branch:** `feat/local-macos-fullstack-acceptance`  
**Starting main SHA:** `9ae3d7e646e3e39d0886765bfa6a60d77dde0529` (2026-11-05).  
**State:** A0 host/source audit recorded in [ENVIRONMENT_AUDIT.md](ENVIRONMENT_AUDIT.md)
and [DEPENDENCIES.md](DEPENDENCIES.md); reproducible inventory: `scripts/local/audit.sh`.
A1 infrastructure and post-migration permission gates **PASS** on the SHA recorded
in [ACCEPTANCE_REPORT.md](ACCEPTANCE_REPORT.md).
A2 API-02–API-06 **CLOSED / PASS**, including the shared image picker; see
[A2_ACCEPTANCE.md](A2_ACCEPTANCE.md) for its qualified SHA and evidence.
A3–A5 remain pending. Full-stack acceptance remains NOT ACCEPTED.

## Repository baseline inspected

- `infra/compose/compose.dev.yml`: PostgreSQL `postgres:18.6-bookworm`, RustFS `rustfs/rustfs:1.0.4`, `rustfs-bootstrap` (`rustfs/rc:v0.1.30`). DEV host bindings `127.0.0.1:5432`, `127.0.0.1:9000`, `127.0.0.1:9001`.
- `infra/scripts/init-secrets.sh dev` provisions separate secrets; PostgreSQL owner/migrator/runtime identities; RustFS backend IAM; default bucket `voxprep-assets`.
- `backend/`: Java 21, Spring Boot 4.1.2, Liquibase, MVC Content Studio, Actuator, S3 integration. DEV run documented in `backend/README.md`.
- `worker/`: Python 3.12, Piper + FFmpeg, backend-controlled model catalog and lease-based jobs. See `worker/README.md`.
- `mobile/careerspeak_app/`: Flutter. Its README describes an early mock slice; **do not assume** current production entrypoint is mock or live: inspect source and selectors.

## Order and ownership

| Agent | Task | Dependency | Deliverables |
|---|---|---|---|
| A0 | [Mac audit](A0_ENVIRONMENT_AUDIT.md) | none | environment evidence, blockers |
| A1 | [PostgreSQL / RustFS](A1_INFRASTRUCTURE.md) | A0 | persistent DEV infra and smoke |
| A2 | [Backend / Content Studio](A2_BACKEND_CONTENT_STUDIO.md) | A1 | backend, migrations, publication evidence |
| A3 | [Piper Worker](A3_PIPER_WORKER.md) | A2 | real TTS output |
| A4 | [Flutter / Drift](A4_FLUTTER_DRIFT.md) | A2 | real mobile client and offline reopen |
| A5 | [End-to-end](A5_E2E_ACCEPTANCE.md) | A3 + A4 | exact-SHA qualification report |

A3 and A4 may execute in parallel if working files do not overlap. Run [Codex orchestrator prompt](CODEX_ORCHESTRATOR.md) from repo root. See [smoke matrix](SMOKE_MATRIX.md).

## Target topology

```text
MacBook
 ├── Docker Compose: PostgreSQL 18.6 [127.0.0.1:5432]
 │                 + RustFS S3 [127.0.0.1:9000], console [:9001]
 ├── Host: Java 21 Spring Boot backend → PostgreSQL + RustFS
 ├── Docker: Worker → host backend (host.docker.internal) → Piper/FFmpeg
 └── Host: Flutter macOS / iOS Simulator → backend HTTP → Drift → offline reopen
```

Prefer native backend and Flutter to ease debugging; keep existing containerized Worker. Verify actual ports, platform support, network paths, dependencies and authentication from code. Flutter/Worker never receive RustFS credentials.

## Existing startup reference

```bash
./infra/scripts/init-secrets.sh dev
docker compose --env-file infra/env/dev.env.example -f infra/compose/compose.dev.yml config
docker compose --env-file infra/env/dev.env.example -f infra/compose/compose.dev.yml up -d --wait postgres rustfs
docker compose --env-file infra/env/dev.env.example -f infra/compose/compose.dev.yml run --rm rustfs-bootstrap
(cd backend && mvn -B -ntp spring-boot:run -Dspring-boot.run.profiles=dev)
```

These commands come from the existing runbooks; do not mistake a documented command for an executed acceptance. Verify Java, Docker, Flutter, architecture and port availability locally first.

## Proposed operator commands (to be implemented, not present yet)

```bash
./scripts/local/up.sh
./scripts/local/status.sh
./scripts/local/logs.sh
./scripts/local/smoke-all.sh
./scripts/local/down.sh
```

`up` should start infra/backend/worker and output **the actual Flutter command/target**; GUI startup may require human target selection. `down` must not remove persistent volumes or delete secrets; never run `down -v` implicitly.

## Global rules

1. Inspect real source routes, profiles, resource paths and test infrastructure before implementing; don't invent API endpoints or CLI flags.
2. No production config/secret changes; no secrets in Git, logs or evidence.
3. No mock Piper, H2, mock storage, in-memory repositories or pre-generated MP3 for real acceptance.
4. Separate PostgreSQL migration/runtime roles; rustfs root/bootstrap vs backend IAM.
5. Preserve production business contracts, permissions, content revision semantics, lease ownership and replay protection.
6. All smoke scenarios must return **PASS / FAIL / BLOCKED** with evidence. An unexecuted check is **NOT RUN**, not PASS.
7. Anchor acceptance to one exact git SHA and record command, exit code, timestamp, platform and evidence path. Run tests again after changes.
8. Do not merge or declare accepted before green tests and a verified user story.

## Expected evidence

`docs/local-macos/ENVIRONMENT_AUDIT.md`, `DEPENDENCIES.md`, `FLUTTER_RUNBOOK.md`, `ACCEPTANCE_REPORT.md` (generated during implementation); local evidence under **gitignored** `artifacts/local-smoke/`. No personal, store or production credentials in artifacts.
