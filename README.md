# CareerSpeak

**CareerSpeak** is a mobile application for IELTS preparation, professional English and international job-interview training.

Repository codename: **VoxPrep**.

## Product loop

```text
LEARN → LISTEN → REPEAT → TEST → REVIEW
```

CareerSpeak is an English-only learning product. Other supported languages are used for UI localization, translations, hints and explanations.

## Core product areas

- IELTS Vocabulary, collocations and contextual examples
- IELTS Speaking and IELTS-style Mock Tests
- English Topics and Shadowing
- General / HR / Behavioral / STAR interviews
- Profession-specific interview tracks
- Reusable Question Bank and Practice Tests
- Local favorites, progress and review
- Offline content packs
- Web-based Content Studio
- Pre-generated reviewed audio
- Optional Study Ambience themes with Focus Mode

## Architecture baseline v0.6

```text
Learners
   │
   ▼
Flutter Mobile
   │
   ├──────────────► CareerSpeak REST API
   │                       │
   │                       ▼
   │                   PostgreSQL
   │
   └──────────────► CDN / Edge
                           │
                           ▼
                         RustFS
                    published media origin

Content team
   │
   ▼
Browser
   │
   ▼
Spring MVC Content Studio
   │
   ├──────────────► PostgreSQL
   │                  │
   │                  ├── content/revisions
   │                  ├── TTS jobs
   │                  ├── availability state
   │                  └── voice/model registry
   │
   └──────────────► RustFS
                      ├── private Piper models
                      ├── draft assets
                      └── generated media

Local Headless TTS Worker
Python + Piper + FFmpeg
   │
   ├── authenticated HTTPS job protocol
   ├── local immutable model cache
   └── presigned GET/PUT to RustFS
```

The backend is a **Spring Boot modular monolith**. MVP does not require Eureka, a separate API Gateway, RabbitMQ, Kafka, Redis, Kubernetes, R2DBC/WebFlux, JavaFX or a PySide6 moderator UI.

## Technology baseline

- Flutter — learner mobile application
- Java 21 + Spring Boot — backend
- Spring MVC + Thymeleaf + HTMX — Content Studio
- Spring Security — moderator/admin security
- Spring Data JPA + Hibernate + HikariCP — persistence layer
- PostgreSQL + Liquibase — durable data/job store
- Python + Piper + FFmpeg — headless TTS worker
- RustFS — S3-compatible object storage
- CDN/edge layer — published immutable learner media
- DigitalOcean Managed PostgreSQL — production database target
- Docker — backend packaging

## Content delivery and availability

Learner catalog APIs use cursor/keyset pagination and expose only content that is both published and active.

```text
publication_status = PUBLISHED
AND
availability_status = ACTIVE
```

Publication lifecycle and learner availability are separate concepts. A published item may be deactivated without destructive deletion.

Flutter synchronizes content through a compact root manifest plus pack manifests. Server-side removals/deactivations are propagated through tombstones so stale local assets can be reclaimed.

## Local retention

Flutter keeps learner progress separately from re-downloadable content/media.

```text
Durable local state
├── favorites
├── progress
├── test attempts
├── review schedule
└── settings

Disposable/re-downloadable state
├── pack snapshots
├── audio
├── remote images
└── future downloadable theme assets
```

Automatic cache management uses:

```text
TTL
+
LRU
+
local storage quota
+
pinning / explicit-download protection
+
asset reference tracking
```

Evicting media must not erase learner progress. Shared assets are physically removed only when no retained local content references them.

## TTS model

TTS is a **content-production pipeline**, not a learner runtime dependency.

```text
DRAFT
  ↓
READY_FOR_AUDIO
  ↓
AUDIO_PENDING
  ↓
AUDIO_GENERATING
  ↓
AUDIO_READY
  ↓
REVIEW
  ↓
PUBLISHED
```

### Voice governance

CareerSpeak separates a logical moderator-facing voice from a physical immutable Piper model.

```text
TtsVoice
US / Female / Lessac
        │
        ├── Model v1 DEPRECATED
        └── Model v2 ACTIVE
```

Each TTS job resolves and stores an exact `voice_model_id`. A worker must never silently substitute another voice/model.

### Model storage

Piper `.onnx` and config files are stored privately in RustFS.

```text
Admin upload
    ↓
presigned PUT
    ↓
RustFS
    ↓
checksum/runtime qualification
    ↓
APPROVED / ACTIVE
```

A worker downloads an exact model revision only when it is missing from its local cache, verifies SHA-256 and then uses it for generation.

## Privacy model

CareerSpeak does not require a personal learner account in MVP.

Learner state such as favorites, progress, test attempts and downloads remains local by default.

A random `installationId` may be used only for technical purposes such as entitlement/security/abuse protection and must not become a learner profile.

Locale selection uses explicit user choice and OS locale/region; GPS is not required for language selection.

## Study Ambience

Visual backgrounds are optional and client-side for MVP.

Initial candidate themes:

```text
MINIMAL
NATURE
COSMOS
LIBRARY
COFFEE_STUDY
PROFESSIONAL
```

Study Mode may use themed backgrounds; Focus/Exam modes prefer minimal presentation. Background selection should be deterministic and must never reduce text readability.

## Specifications

- [System Requirements & Architecture Specification v0.5](docs/specification/CAREERSPEAK_SYSTEM_REQUIREMENTS.md)
- [Content Delivery, Availability & Local Retention Requirements v1.0 — v0.6 normative addendum](docs/specification/CAREERSPEAK_CONTENT_DELIVERY_RETENTION.md)
- [Globalization & Localization Requirements](docs/specification/CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md)
- [Spring MVC + Local Headless Piper Worker Architecture v1.1](docs/architecture/CAREERSPEAK_TTS_PIPELINE.md)

## Current stage

```text
P0 — Architecture Freeze / System Design
```

Next deliverables:

1. Domain map
2. Full PostgreSQL ERD
3. Content revision/publication/availability model
4. Localization model
5. Assessment snapshot model
6. TTS voice/model/job ERD
7. RustFS FileAsset/model storage model
8. Cursor-pagination query/index model
9. Content manifest, tombstones and offline-pack model
10. Flutter local retention/cache schema
11. OpenAPI contracts
12. ADR baseline
13. P0 implementation backlog

## Commercial model

Initial strategy:

```text
One-time purchase
No mandatory subscription
No ads
No learner runtime AI/STT/TTS cost
```

The product differentiator is curated English content for IELTS and profession-specific international interviews, supported by reusable tests, multilingual hints, reviewed pre-generated audio, controlled offline storage and privacy-first learning.