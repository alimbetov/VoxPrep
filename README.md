# CareerSpeak

CareerSpeak is a mobile application for IELTS preparation, professional English and international job-interview training.

Repository codename: **VoxPrep**.

## Product loop

```text
READ → LISTEN → REPEAT → TEST → REVIEW
```

CareerSpeak teaches English only. Other languages are used for UI, translations, hints and explanations.

## Architecture baseline v0.8

```text
Flutter
  │
  ├── installation token ──► Spring Boot REST API ──► PostgreSQL
  │
  └── media ───────────────► CDN/Edge ─────────────► RustFS

ADMIN Browser
  │
  └── session ─────────────► Spring MVC Content Studio
                                │
                                ├── PostgreSQL
                                └── RustFS

TTS Worker
  │
  ├── machine token ───────► Backend Job API
  ├── exact Piper model ◄── RustFS / local cache
  ├── Piper + FFmpeg
  └── generated audio ─────► RustFS
```

The backend is a **Spring Boot modular monolith**.

## Three actors only

### ADMIN

One secured administrative account:

```text
fixed username
strong deployment-managed password hash
Spring Security server-side session
```

ADMIN performs all authoring, localization, TTS model/voice management, audio review, publication and activation/deactivation.

### Flutter Installation

No personal learner account:

```text
first launch
→ random installationId
→ backend registration
→ backend-issued installation token
→ Secure Storage
```

Learner progress/favorites/test history stay local by default.

### TTS Worker

Server-managed long-running Python process/container:

```text
Python + Piper + FFmpeg
machine token
auto-start / auto-restart
local immutable model cache
```

## Backend stack

```text
Java 21
Spring Boot
Spring MVC
Spring Security
Spring Data JPA
Hibernate
HikariCP
PostgreSQL
Liquibase
Thymeleaf
HTMX
OpenAPI
Micrometer / Actuator
Testcontainers
Docker
```

Not required initially:

```text
R2DBC / WebFlux
Redis
Caffeine
RabbitMQ
Kafka
Eureka
Kubernetes
Elasticsearch
```

## Flutter mobile baseline

```text
Flutter + Dart
Riverpod
go_router
Drift + SQLite
Secure Storage
local filesystem
HTTP API adapter
shared audio playback abstraction
```

Feature-first modules include:

```text
onboarding
home
vocabulary
interview
topics
phrases
shadowing
assessment
review
favorites
downloads
settings
storage_management
```

Shared mobile services:

```text
ContentSyncCoordinator
DownloadManager
AssetResolver
StorageRetentionManager
AudioPlaybackController
ReviewScheduler
```

## Language support

CareerSpeak separates application UI localization from educational content localization.

### UI strings

```text
ARB
Flutter gen-l10n
```

Initial UI locales:

```text
en
ru
kk
```

### Content translation

Backend-driven:

```text
translation
hint
explanation
localized labels
```

Flutter distinguishes:

```text
uiLocale
translationLocale
preferredAccent
```

English remains the fixed learning language. Content locale changes use locale deltas and SHOULD NOT redownload unchanged English audio.

## Offline-first mobile flow

```text
START
→ open Drift/local files
→ load settings/locale/theme
→ load cached content
→ render UI immediately
→ sync manifests in parallel
```

Content updates use:

```text
root manifest
pack manifests
locale deltas
tombstones
checksums
staging + verification + atomic activation
```

A failed update never replaces the last known-good local snapshot.

## Downloads and assets

`DownloadManager` handles:

```text
QUEUED
DOWNLOADING
VERIFYING
READY
PAUSED
FAILED
CANCELLED
```

`AssetResolver` hides storage source:

```text
verified local file
or
CDN/Edge → RustFS
```

## Audio / Shadowing

Shared playback supports:

```text
play/pause/seek
0.75x / 1.0x / 1.25x
repeat 1 / 3 / 5 / infinite
skip back/forward
segment repeat where deterministic segmentation exists
```

Shadowing uses backend-published stable segment/order metadata rather than punctuation guessing.

## Content lifecycle

```text
DRAFT
→ READY_FOR_AUDIO
→ READY_FOR_REVIEW
→ PUBLISHED
→ ARCHIVED
```

Availability is separate:

```text
ACTIVE
INACTIVE
```

Learner API exposes only:

```text
PUBLISHED + ACTIVE
```

## Content delivery and retention

Learner collections use cursor/keyset pagination.

Flutter keeps durable progress separate from re-downloadable content/media.

Automatic cleanup uses:

```text
TTL
+
LRU
+
local storage quota
+
pin/manual-download protection
+
reference-safe shared-asset deletion
```

Media eviction never removes learner progress.

## TTS queue

PostgreSQL is the durable queue.

Worker claim uses an atomic transaction based on:

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

## Specifications

- [System Requirements & Architecture Specification v0.8](docs/specification/CAREERSPEAK_SYSTEM_REQUIREMENTS.md)
- [Flutter Mobile Application Requirements v1.0](docs/specification/CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md)
- [Globalization & Localization Requirements v0.5](docs/specification/CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md)
- [Content Delivery, Availability & Local Retention Requirements v1.1](docs/specification/CAREERSPEAK_CONTENT_DELIVERY_RETENTION.md)
- [TTS Worker & Audio Production Architecture v1.2](docs/architecture/CAREERSPEAK_TTS_PIPELINE.md)
- [P0 Domain & Contract Design Plan v1.2](docs/architecture/CAREERSPEAK_DOMAIN_CONTRACT_PLAN.md)

## Current stage

```text
P0 — Domain & Contract Design
branch: feat/p0-domain-contracts
```

Execution order:

```text
P0.0  Common Contracts
P0.1  Revision / Publication / Availability
P0.2  Profession / Catalog
P0.3  Localization
P0.4  Media / RustFS
P0.5  TTS
P0.6  Interview
P0.7  Vocabulary
P0.8  Topic / Phrase / Shadowing Content
P0.9  Assessment
P0.10 Manifest / Content Delivery
P0.11 Pagination Contract
P0.12 Flutter Application Contract
P0.13 Security / Installation
P0.14 Content Studio
P0.15 Integrated ERD + Mobile ERD + OpenAPI
P0.16 Architecture Freeze
```

P0.12 includes feature boundaries, Riverpod ownership, navigation, Drift ERD, installation/API client, localization/RTL, manifest sync, downloads, asset resolution, audio/shadowing, assessment, review scheduling, retention and recovery behavior.
