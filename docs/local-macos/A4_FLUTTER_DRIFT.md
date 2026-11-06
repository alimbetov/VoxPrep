# A4 — Flutter real HTTP → Drift → offline reopen

## Codex task

Inspect current `mobile/careerspeak_app` beyond early `README.md`; find actual real-API entrypoint, Riverpod providers, HTTP client, Drift storage/SQLite initialization, platform runners, auth/installation identity and feature flags.

1. Run `flutter doctor -v`, `flutter pub get`, `flutter analyze`, `flutter test`. Capture exact SDK, target, exit codes.
2. Use currently supported real integration entrypoint, not `main_demo.dart` or `MockContentRepository` during acceptance.
3. Configure dev backend URL through existing mechanism or `--dart-define`. On macOS/iOS simulator verify host routing, ATS/network permissions and SQLite plugins. Avoid hardcoding localhost in domain code.
4. Build/run on a real available iOS Simulator and/or native macOS (separate verdicts). If runner missing, use `flutter create --platforms=<target> .` only after impact assessment and preserve existing code.
5. Check live catalog and material fetch, schema/decoder validation, Drift transactions, CURRENT N state, download integrity, cold restart offline, payload N→N+1, corrupted payload fail-closed to CURRENT N and retry to N+1.
6. Check FREE first material, FULL lock without fake purchase, local audio playback if supported, meaningful screenshot and real UI evidence.
7. Implement `scripts/local/flutter-run.sh`, `smoke-flutter.sh`, `docs/local-macos/FLUTTER_RUNBOOK.md`, deterministic test control around network on/off.

## Smoke IDs

FLT-01 actual device startup; FLT-02 content read via real backend; FLT-03 persisted Drift material; FLT-04 offline cold reopen; FLT-05 CURRENT N→N+1 atomicity + retry; FLT-06 FREE/FULL and audio behavior.

## Done

Document real target name, command, screen captures, HTTP requests, Drift evidence and offline process restart. Do not confuse mock UI, iOS and macOS results.
