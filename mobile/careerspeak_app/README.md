# CareerSpeak Flutter — P1 Mock UI

This directory is the first executable learner-facing slice of CareerSpeak.

## Scope

Mock-only vertical slice:

```text
Home
Learn catalogue + search/filter
Content detail
FAVORITE / LISTENED / COMPLETED
Tests catalogue
Review
Settings / theme mode
Material Design 3
adaptive NavigationBar / NavigationRail
```

No Backend, Drift, Secure Storage, CDN or real audio is connected in this branch.

## Architecture

```text
UI / Riverpod controllers
        ↓
domain models
        ↑
MockContentRepository
```

The mock adapter is intentionally replaceable. Feature widgets must not depend on HTTP/Drift types.

## Generated DEV/TEST demo content

The project has a reproducible mock-data generator shared with Backend tests.
Run from the **repository root** (Python 3.12+):

```powershell
python tools/generate_demo_catalogue.py
python tools/generate_demo_catalogue.py --check
```

To generate a larger repeatable dataset:

```powershell
python tools/generate_demo_catalogue.py --seed 42 --count 64
```

The default 32 items are generated into
`lib/data/mock/generated_demo_content.dart`, which is consumed by
`MockContentRepository`. The same seed also generates Backend's
`src/test/resources/fixtures/demo_catalogue_seed.json`.
The shared JSON marks the first example in each category FREE and later
examples FULL for test scenarios; the Flutter `ContentItem` currently
does **not** carry those access labels. This is a **demo fixture**, not a
Store purchase or server entitlement.

The generator does not initialize browser SQLite/Drift. The Flutter Web
bootstrap issue must be addressed separately before expecting the full app
to launch in Chrome. See
[`R5_DEV_TEST_MOCK_DATA.md`](../../docs/qualification/R5_DEV_TEST_MOCK_DATA.md).

## Dependencies

- Flutter stable with Dart >= 3.12
- flutter_riverpod 3.4.x
- go_router 18.1.x

## Local bootstrap

The repository was documentation-only before P1, so platform runner folders are generated locally once with Flutter tooling:

```bash
cd mobile/careerspeak_app
flutter create --platforms=android,ios,windows,web .
flutter pub get
flutter analyze
flutter test
flutter run
```

Windows/web are useful for fast adaptive-layout qualification; Android/iOS remain the product targets.

## P1 rule

Do not add production persistence/networking until the mock UX and state semantics are accepted.
