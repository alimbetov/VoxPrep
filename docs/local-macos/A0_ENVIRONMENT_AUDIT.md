# A0 — MacBook environment / source audit

## Codex task

Inspect current `main` ancestry, branch status and the actual local Mac environment. Run and save version outputs for `uname -m`, `sw_vers`, RAM/disk, `git`, `docker version`, `docker compose version`, `java -version`, `mvn -version`, `python3 --version`, `flutter doctor -v`, `xcodebuild -version`, `xcrun simctl list devices available` and CocoaPods where relevant. Check for port collisions on 5432/9000/9001 and backend's configured port; inspect volumes without deleting anything.

Audit current source and documentation in `infra/`, `backend/`, `worker/`, `mobile/careerspeak_app/`:
- actual Java/Spring and Python/Flutter versions;
- native vs container execution, architecture image support, required memory/disk, download requirements;
- current MVC routes, backend health endpoints and HTTP content manifest APIs;
- Worker `BASE_URL`, `WORKER_TOKEN`, backend private APIs, voice model catalog;
- actual real Flutter entrypoint, HTTP config, Drift wiring, iOS/macOS runner and plugin compatibility; distinguish stale README from current code;
- existing test fixtures/acceptance runners and missing integration capabilities.

## Deliverables

`docs/local-macos/ENVIRONMENT_AUDIT.md` and `DEPENDENCIES.md` with READY/MISSING/BLOCKED, exact commands, versions, architecture, ports, storage, backend host IP/port, evidence and scope-specific blockers. Do not install intrusive system software or mutate production.

## Done

Actual MacBook readiness and exact next commands are documented; each blocker has an owner and remediation. Unknown/untested != READY.
