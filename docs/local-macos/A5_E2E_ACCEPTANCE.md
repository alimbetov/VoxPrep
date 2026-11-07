# A5 — Exact-SHA end-to-end smoke and fault injection

## Codex task

Coordinate A0–A4; integrate tests in `scripts/local/smoke-all.sh` and report `docs/local-macos/ACCEPTANCE_REPORT.md`. Use `SMOKE_MATRIX.md` as strict gate.

## Real user stories

1. US-01: authenticated Content Studio → create material, image/media, XML template + import/validation where supported → approve → publish → inspect PostgreSQL and RustFS.
2. US-02: Backend HTTP CURRENT/manifest/payload → Flutter decoder → Drift stored material and media metadata.
3. US-03: stop backend or disconnect device from network → terminate/restart Flutter → previously downloaded material still opens.
4. US-04: backend catalog model → PENDING TTS job → Worker lease → real Piper/FFmpeg MP3 → backend finalization → RustFS READY.
5. US-05: authorized Content Studio player retrieves and plays **that** MP3; save UI screenshot and asset evidence.
6. US-06: real publication N+1, Flutter atomic update. Fault injection: network broken during payload and corrupt checksum must keep CURRENT N; retry downloads N+1; offline reopen N+1.

## Fault injection

Bad XML; DB unavailable; RustFS unavailable; unauthorized calls; invalid Piper SHA; worker lease expiration; replay; duplicate manifest sync; partial HTTP payload; worker restart. Restore normal service nondestructively and rerun affected checks.

## Reporting

For every test ID: `status = PASS | FAIL | BLOCKED | NOT RUN`, required precondition, command, exit code, timestamp, exact SHA, elapsed time, evidence path, assertion and fix if failed.

Capture `git rev-parse HEAD` **before and after** tests. If code changes after run, rerun suite on new SHA. Include `flutter analyze/test`, backend Maven test/verify, Worker pytest, API probes and E2E assertions as applicable. Save secret-redacted logs only under gitignored `artifacts/local-smoke/`.

## Done

Complete all 24 mandatory tests PASS on one SHA, plus user-story evidence and negative qualification. Otherwise result NOT ACCEPTED, listing specifically what is blocked. Never report an unexecuted check as green.
