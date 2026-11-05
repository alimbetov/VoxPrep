# Flutter DEV Web Preview — browser without Backend or SQLite

This is a **standalone, explicitly marked UX showcase**. It reuses the
product's Material 3 theme, typed generated `ContentItem` fixtures and
`MockTestRepository`. It is not the full production `CareerSpeakApp`;
the real release continues to use HTTP, Drift, installation identity,
content publication and Store verification.

## Run from Windows PowerShell

From repository root:

```powershell
cd mobile/careerspeak_app
flutter create --platforms=web .
flutter pub get
flutter run -d chrome -t lib/demo_web_main.dart --web-port=3000 --dart-define=VOXPREP_DEMO=true
```

Open `http://localhost:3000` if Chrome does not open automatically.

This launch **does not need** Docker, PostgreSQL, RustFS, Spring Boot,
`sqlite3.wasm` or registered Play/App Store accounts.

Features: responsive Home/Learn/Tests/Review/Settings, search through the
generated catalogue, detail previews, in-memory favorites/completion,
practice quiz scoring and a conspicuous `Simulate FULL (demo only)`
control. The FULL control is not linked to billing, network calls or server
entitlements; no data persists after refresh. All content and assessment
questions come from the tracked mock fixtures.

The entrypoint enforces **debug mode** and the explicit
`VOXPREP_DEMO=true` compile-time value; release/production builds cannot
launch this demo mode. The production default `lib/main.dart` is unchanged.

## Important scope

This is deliberately **not** a replacement for real Flutter screens nor
proof of a production E2E release. In particular, it does not exercise
real installation bootstrap, publisher HTTP, full Drift offline persistence,
audio/TTS, content membership, Google/Apple purchases or restore/refund.
These require separate acceptance jobs. See
[`ADMIN_FLUTTER_USER_STORY_ACCEPTANCE.md`](ADMIN_FLUTTER_USER_STORY_ACCEPTANCE.md).
