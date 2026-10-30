# CareerSpeak

CareerSpeak is an offline-first Flutter application for IELTS preparation, professional English and international job-interview training.

Repository codename: **VoxPrep**.

## Product loop

```text
READ → LISTEN → REPEAT → TEST → REVIEW
```

CareerSpeak teaches English only. Other languages support UI, translations, hints and explanations.

## Architecture baseline v0.10

```text
Flutter App
  ├── installation token ──► Spring Boot REST API ──► PostgreSQL
  └── media ───────────────► CDN/Edge ─────────────► RustFS

ADMIN Browser
  └── session ─────────────► Spring MVC Content Studio
                                ├── PostgreSQL
                                └── RustFS

TTS Worker
  ├── machine token ───────► Backend Job API
  ├── exact Piper model ◄── RustFS/local cache
  ├── Piper + FFmpeg
  └── generated audio ─────► RustFS
```

Backend is one **Spring Boot modular monolith**.

## Three actors only

```text
ADMIN
FLUTTER INSTALLATION
TTS WORKER
```

### ADMIN

One fixed secured account with server-side session. No Moderator/Editor/Reviewer hierarchy, OAuth, LDAP, Keycloak or RBAC tables in MVP.

### Flutter Installation

```text
random installationId
→ backend registration
→ backend-issued installation token
→ platform Secure Storage
```

No personal learner account. Progress/favorites/test history remain local-first.

### TTS Worker

Server-managed long-running Python process/container:

```text
Piper + FFmpeg
machine token
auto-start/restart
local exact-model cache
```

No direct PostgreSQL credentials and no permanent RustFS credentials.

## Standard lifecycle vocabulary

```text
Backend:
PUBLISHED + ACTIVE
= learner-deliverable/downloadable

Flutter metadata:
CURRENT
= local metadata revision currently used

Flutter offline:
READY
= complete required offline asset set locally verified
```

These are deliberately separate state machines.

## Learner markers

Flutter keeps independent durable local markers:

```text
FAVORITE  = explicit user curation
LISTENED  = qualified audio consumption
COMPLETED = pedagogical completion
```

Any valid combination is allowed, including:

```text
FAVORITE + LISTENED + COMPLETED
```

Markers survive metadata refresh and cache/media eviction.

Catalogs may filter by:

```text
Favorites
Listened / Not listened
Completed / Not completed
```

Favorite does not automatically pin offline media.

## Content versioning

Backend publishes one root:

```text
contentVersion
```

The root references exact pack variants:

```text
JAVA_SENIOR / canonical / rev 8
JAVA_SENIOR / locale:kk / rev 4
```

Locale deltas do not create independent root epochs.

Flutter stages/verifies metadata and atomically switches to the new `CURRENT` root snapshot.

## Offline replacement

Metadata and offline binaries are separate.

Valid state:

```text
metadata rev 8 = CURRENT
offline rev 7 = READY
offline rev 8 = UPDATING
```

The old READY bundle remains usable until replacement verifies.

## Flutter baseline

```text
Flutter + Dart
Material Design 3
Riverpod
go_router
Drift + SQLite
Secure Storage
local filesystem
ContentSyncCoordinator
DownloadManager
AssetResolver
AudioPlaybackController
StorageRetentionManager
ReviewScheduler
LearnerContentStateRepository
```

## Material Design 3

Material Design 3 is the **single CareerSpeak UI design system** on Android and iOS.

```text
Material Design 3
        ↓
CareerSpeak Theme + Design Tokens
        ↓
CareerSpeak reusable Material components
        ↓
Adaptive feature UI
```

Baseline rules:

```text
ThemeData / ColorScheme
System / Light / Dark
NavigationBar / NavigationRail
central spacing/radius/type/motion tokens
Material components before bespoke replacements
Study Ambience is decorative, not a second UI system
```

## Adaptive UI

Layout is based on current available window width, not device names:

```text
COMPACT   < 600
MEDIUM    600–839
EXPANDED  840–1199
LARGE     >= 1200
```

The same route/domain/audio/test/marker state is preserved across phone/tablet/landscape/split-screen layouts.

Large text, RTL and mixed RTL guidance + LTR English learning text are qualification requirements.

## Local data

Drift separates:

```text
SYSTEM / SYNC STATE
VERSIONED CONTENT / CACHE
DURABLE LEARNER STATE
```

Durable learner state includes:

```text
FAVORITE
LISTENED
COMPLETED
feature progress
review schedule
test history
```

Automatic disposable-storage management:

```text
TTL + LRU + quota + pin/download protection + reference-safe deletion
```

Cache/media eviction never deletes learner progress or markers.

## TTS queue

PostgreSQL is the durable queue.

Atomic claim uses:

```sql
FOR UPDATE SKIP LOCKED
```

with:

```text
worker_id
lease_token
lease_until
heartbeat
attempt_count
fingerprint
```

RabbitMQ is not required initially.

## Backend stack

```text
Java 21
Spring Boot
Spring MVC
Spring Security
Spring Data JPA / Hibernate
HikariCP
PostgreSQL
Liquibase
Thymeleaf + HTMX
OpenAPI
Micrometer / Actuator
Testcontainers
Docker
```

Not required initially:

```text
R2DBC/WebFlux
Redis
RabbitMQ
Kafka
Eureka
Kubernetes
Elasticsearch/OpenSearch
```

## Normative specifications

- [System Requirements & Architecture Specification v0.10](docs/specification/CAREERSPEAK_SYSTEM_REQUIREMENTS.md)
- [Cross-System Contract Standard v1.0](docs/architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md)
- [Flutter Mobile Application Requirements v2.1](docs/specification/CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md)
- [Globalization & Localization Requirements v1.0](docs/specification/CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md)
- [Content Delivery & Local Retention Requirements v2.0](docs/specification/CAREERSPEAK_CONTENT_DELIVERY_RETENTION.md)
- [TTS Worker & Audio Production Architecture v2.0](docs/architecture/CAREERSPEAK_TTS_PIPELINE.md)
- [P0 Domain & Contract Design Plan v2.1](docs/architecture/CAREERSPEAK_DOMAIN_CONTRACT_PLAN.md)

## Mobile detailed design

- [P0.12.4 Drift ERD v1.1](docs/mobile/CAREERSPEAK_DRIFT_ERD.md)
- [P0.12.7 ContentSyncCoordinator v1.0](docs/mobile/CAREERSPEAK_CONTENT_SYNC_COORDINATOR.md)
- [Adaptive / Responsive UI Contract v0.1](docs/mobile/CAREERSPEAK_ADAPTIVE_UI.md)
- [Material Design 3 Design System v1.0](docs/mobile/CAREERSPEAK_MATERIAL_DESIGN_3.md)
- [Learner Content State & Markers v1.0](docs/mobile/CAREERSPEAK_LEARNER_CONTENT_STATE.md)

## Current P0 direction

Before executable implementation, freeze:

```text
P0.0  Common contracts
P0.1  Publication / Availability
P0.2  Profession / Catalog
P0.3  Localization
P0.4  Media / RustFS
P0.5  TTS
P0.6  Interview
P0.7  Vocabulary
P0.8  Topic / Phrase / Shadowing
P0.9  Assessment
P0.10 Manifest / Content Delivery
P0.11 Pagination
P0.12 Flutter Application Contract
      ├── Material Design 3
      ├── Adaptive UI
      └── Learner markers
P0.13 Security / Installation
P0.14 Content Studio
P0.15 Integrated ERD + OpenAPI
P0.16 Architecture Freeze
```

The product differentiator is curated profession-specific and IELTS English content with reviewed audio, deterministic assessment, offline-first consumption and a deliberately simple runtime architecture.