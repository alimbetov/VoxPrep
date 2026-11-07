# Master prompt for Codex — VoxPrep local macOS

You are the lead engineer for the existing repository `alimbetov/VoxPrep`. Your goal is to implement the work described in `docs/local-macos/`, **not simply write more plans**. Work in branch `feat/local-macos-fullstack-acceptance`. Before any edit, inspect `git status`, current SHA, source, existing runbooks and CI.

Use tasks A0 → A1 → A2 → (A3 || A4) → A5. If subagents exist, delegate non-overlapping paths; otherwise execute sequentially. Report blockers promptly and fix the root cause where safe.

## Non-negotiables

- Run on the **actual MacBook**, record chip architecture and macOS version, validate arm64 containers; don't claim you executed on local hardware when remote.
- Reuse `infra/compose/compose.dev.yml`, `init-secrets.sh`, Spring Boot's `dev` profile and existing backend/worker/Flutter implementations.
- Dev secrets stay outside tracked files; never expose them in prompts, stdout or commits.
- Never reset/destroy databases/volumes or edit production without explicit approval; all cleanup is nondestructive.
- Use real PostgreSQL, RustFS, backend, Piper voice model, FFmpeg and Flutter/Drift. Mocks may be used in unit tests but cannot satisfy the E2E gate.
- For Flutter determine **which current entrypoint uses real API**, platform runner support and how networking works on the target. Don't conflate mock demo with accepted mobile app.
- For Worker resolve backend address from inside Docker (`host.docker.internal` under Docker Desktop), and keep the worker's security token server-managed.
- Maintain deterministic fixtures and current content publication/revision APIs; no hand-written DB inserts bypassing domain rules for E2E.
- Implement local operator scripts with robust error handling, `set -euo pipefail`, explicit timeouts, `trap` cleanup only for ephemeral resources, redacted logs and port collision detection.
- Put runnable tests in version control, store secret-free runtime evidence under gitignored `artifacts/local-smoke/`.
- When a service is inaccessible or a capability missing, report BLOCKED with exact cause, source path, next fix. Never fabricate PASS.

## Full user stories

- US-01: Content Studio creates, validates, approves and publishes material and image; PostgreSQL and RustFS hold real state.
- US-02: Published content is served by actual backend HTTP; Flutter decodes it and saves through Drift.
- US-03: Offline reopen still displays previously downloaded content (and downloaded media where the current contract supports it).
- US-04: Backend job → worker claim → exact Piper model/checksum → WAV → FFmpeg MP3 → backend output → RustFS → job READY.
- US-05: MVC Content Studio previews the newly generated MP3 via authorized backend access.
- US-06: Publish new revision N+1; client advances CURRENT atomically and reopens offline. On injected payload failure, CURRENT must remain N.

## Required deliverables

- `scripts/local/up.sh`, `down.sh`, `status.sh`, `logs.sh`, `smoke-infra.sh`, `backend-start.sh`, `smoke-backend.sh`, `worker-start.sh`, `smoke-tts.sh`, `flutter-run.sh`, `smoke-flutter.sh`, `smoke-all.sh` as appropriate.
- Document tested commands and actual endpoints in `docs/local-macos/FLUTTER_RUNBOOK.md`.
- Exact SHA, SQL assertions, S3 round-trip evidence, HTTP hashes, audio `ffprobe` metadata, Flutter/Drift results, device screenshots, negative test results.
- `docs/local-macos/ACCEPTANCE_REPORT.md` enumerating the IDs from `SMOKE_MATRIX.md` with PASS/FAIL/BLOCKED/NOT RUN.

## Definition of Done

All mandatory rows in the smoke matrix pass on the **same exact SHA**; errors are diagnosed and tests rerun. Provide branch, SHA, changed files, exact commands, test counts, evidence locations, remaining blockers. The report says ACCEPTED only when **all** mandatory real integration gates pass. Do not silently merge to main.
