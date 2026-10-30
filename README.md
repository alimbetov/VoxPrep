# CareerSpeak

CareerSpeak is a mobile application for IELTS preparation, professional English and international job-interview training.

Repository codename: **VoxPrep**.

## Product loop

```text
READ → LISTEN → REPEAT → TEST → REVIEW
```

CareerSpeak teaches English only. Other languages are used for UI, translations, hints and explanations.

## Architecture baseline v0.7

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

One secured administrative account for MVP.

```text
fixed username
strong deployment-managed password hash
Spring Security server-side session
```

ADMIN performs all authoring, localization, TTS model/voice management, audio review, publication and activation/deactivation.

No Moderator/Editor/Reviewer hierarchy, user-role tables, OAuth, LDAP or Keycloak in MVP.

### Flutter Installation

No personal learner account.

```text
first launch
→ random installationId
→ backend registration
→ backend-issued installation token
→ secure local storage
```

Learner progress/favorites/test history stay local by default.

### TTS Worker

A server-managed long-running Python process/container:

```text
Python + Piper + FFmpeg
machine token
auto-start / auto-restart
local immutable model cache
```

The worker does not connect directly to PostgreSQL and does not hold permanent RustFS credentials.

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

## TTS queue

TTS jobs use PostgreSQL as a durable queue.

Worker claim is based on an atomic transaction using:

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

This supports one worker now and multiple workers later without introducing RabbitMQ.

## TTS model storage

Logical voice and exact model revision are separate:

```text
TtsVoice
US / Female / Lessac
        │
        ├── Model v1 DEPRECATED
        └── Model v2 ACTIVE
```

Every TTS job resolves an exact immutable `voice_model_id` before execution.

Piper `.onnx` and config files are stored privately in RustFS. Worker downloads a missing exact model through temporary authorization, verifies SHA-256 and caches it locally.

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

## Content delivery

Learner collections use cursor/keyset pagination.

Flutter synchronizes through root/pack manifests and tombstones.

Published media path:

```text
Flutter → CDN/Edge → RustFS
```

Spring Boot does not proxy normal learner media bytes.

## Flutter local retention

Durable learner data is separated from re-downloadable content/media.

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

## Specifications

- [System Requirements & Architecture Specification v0.7](docs/specification/CAREERSPEAK_SYSTEM_REQUIREMENTS.md)
- [Globalization & Localization Requirements v0.4](docs/specification/CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md)
- [Content Delivery, Availability & Local Retention Requirements v1.1](docs/specification/CAREERSPEAK_CONTENT_DELIVERY_RETENTION.md)
- [TTS Worker & Audio Production Architecture v1.2](docs/architecture/CAREERSPEAK_TTS_PIPELINE.md)
- [P0 Domain & Contract Design Plan v1.1](docs/architecture/CAREERSPEAK_DOMAIN_CONTRACT_PLAN.md)

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
P0.8  Topic / Phrase / Shadowing
P0.9  Assessment
P0.10 Manifest / Content Delivery
P0.11 Pagination Contract
P0.12 Flutter Local Domain / Retention
P0.13 Security / Installation
P0.14 Content Studio
P0.15 Integrated ERD + OpenAPI
P0.16 Architecture Freeze
```

The next design slice is **P0.0 Common Contract & Domain Conventions**, followed by **P0.1 Revision / Publication / Availability**.
