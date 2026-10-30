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
