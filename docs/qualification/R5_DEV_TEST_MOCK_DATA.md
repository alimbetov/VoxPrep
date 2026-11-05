# R5 — deterministic DEV/TEST mock data generator

Single canonical generator: `tools/generate_demo_catalogue.py`.

It produces exactly two **synchronized** artifacts from one seed:

1. `mobile/careerspeak_app/lib/data/mock/generated_demo_content.dart` —
   a typed Dart `List<ContentItem>` consumed by the existing
   `MockContentRepository` (search, filters, pagination and detail routes).
2. `backend/src/test/resources/fixtures/demo_catalogue_seed.json` —
   machine-readable example learning content for backend tests and future
   DEV import tooling; **this is not automatically inserted into PostgreSQL
   or published to real learners**.

By default the dataset has 32 English-learning materials, including the
seven original stable demo content codes, categorized Java, Cloud/DevOps,
IELTS, Banking English, Medical English, Vocabulary and Professional English.
Each category starts with one FREE content sample; later examples are
designated FULL **inside the fixture only**. No purchase token or backend
entitlement is generated. The existing Flutter content DTO has no
`accessLevel` property: its generated Dart list is for demo browsing,
while the corresponding JSON preserves the intended access labels for
backend/test-data tooling. The fixture is not a substitute for published
backend access policies.

## Generate locally

From repository root (Python 3.12+, no third-party dependencies):

```powershell
python tools/generate_demo_catalogue.py
python tools/generate_demo_catalogue.py --check
python -m unittest discover -s tools/tests -p "test_*.py" -v
```

The `--seed` and `--count` flags allow deterministic variants:

```powershell
python tools/generate_demo_catalogue.py --seed 42 --count 64
```

Commit **both outputs** after regenerating. CI `DEV Mock Fixture Contract`
runs the default seed 2026 / count 32 `--check` and generator invariants.
Before opening a PR, regenerate with the defaults to avoid stale generated
artifacts.

## Isolation and local preview

The generated Dart content is loaded only by `MockContentRepository`, not
by production HTTP/Drift repositories. Mock billing is permitted only in
debug DEV; production `VOXPREP_BILLING_MODE=disabled` fails closed until
real Store credentials and sandbox acceptance are available.

Flutter DEV launch parameters:

```powershell
flutter run -d chrome --dart-define=VOXPREP_ENV=development --dart-define=VOXPREP_MOCK_BILLING=true --dart-define=VOXPREP_MOCK_PURCHASE=true
```

**Important:** Flutter Web SQLite/Drift setup is a separate issue. The
mock content generator does not bypass platform bootstrap dependencies.
For a browser-only demo without SQLite, a dedicated mock bootstrap path
must be qualified separately.

## Opt-in real DEV PostgreSQL seed (NEW)

The generator still writes only local files; now the Backend also includes a
**DEV-only**, explicit opt-in Spring `ApplicationRunner` that reads the exact
generated fixture and creates real **DRAFT** revisions via
`ContentAuthoringService.createInitialRevision`.

From repository root, generate the three synchronized artifacts first:

```powershell
python tools/generate_demo_catalogue.py
python tools/generate_demo_catalogue.py --check
```

The third generated artifact is
`backend/src/main/resources/dev-fixtures/demo_catalogue_seed.json`.
After starting the normal DEV PostgreSQL/RustFS stack and initializing
development secrets, run Backend from the `backend` directory:

```powershell
$env:VOXPREP_DEV_DEMO_SEED_ENABLED = "true"
mvn spring-boot:run "-Dspring-boot.run.profiles=dev"
```

Backend configuration `voxprep.dev.demo-seed-enabled` must be true; the
Spring component is constrained to `@Profile("dev")` and **does not register
at all** in TEST, staging, or production. It only inserts revisions absent
by exact `contentCode + type + revision=1` and leaves existing revisions
unchanged. Repeated startup does not replace authored work. No publication,
review, TTS jobs, transactions, or purchasing rights are fabricated.

Open `/admin/content` to view seeded drafts. Publishing content to Flutter
still requires building the real catalogue hierarchy, review, approvals and
CURRENT release; simply seeing drafts in Content Studio is **not** evidence
of end-to-end publication.

For a clean local launch without seeding:

```powershell
Remove-Item Env:VOXPREP_DEV_DEMO_SEED_ENABLED -ErrorAction SilentlyContinue
```

The DEV runner is an incremental authoring aid, not the full XML/JSON import
workflow with preview and validation; that workflow remains a separate
acceptance item.
