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

## Architecture baseline v0.4

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
   └──────────────► CDN / DigitalOcean Spaces

Content team
   │
   ▼
Browser
   │
   ▼
Spring MVC Content Studio
   │
   ▼
PostgreSQL TTS Jobs
   │
   ▼
Local Headless Piper Worker
Python + Piper + FFmpeg
   │
   ▼
DigitalOcean Spaces / CDN
```

The backend is a **Spring Boot modular monolith**. MVP does not require Eureka, a separate API Gateway, RabbitMQ, Kafka, Redis, Kubernetes, JavaFX or a PySide6 moderator UI.

## Technology baseline

- Flutter — learner mobile application
- Java 21 + Spring Boot — backend
- Spring MVC + Thymeleaf + HTMX — Content Studio
- Spring Security — moderator/admin security
- PostgreSQL + Liquibase — persistence
- Python + Piper + FFmpeg — headless TTS worker
- DigitalOcean Managed PostgreSQL — production database target
- DigitalOcean Spaces + CDN — published media target
- Docker — backend packaging

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

The worker runs independently, claims durable jobs over authenticated HTTPS, generates speech with Piper, converts/validates it with FFmpeg, uploads production media, and reports completion. Learners consume already-published immutable audio from CDN.

## Privacy model

CareerSpeak does not require a personal learner account in MVP.

Learner state such as favorites, progress, test attempts and downloads remains local by default.

A random `installationId` may be used only for technical purposes such as entitlement/security/abuse protection and must not become a learner profile.

Locale selection uses explicit user choice and OS locale/region; GPS is not required for language selection.

## Specifications

- [System Requirements & Architecture Specification v0.4](docs/specification/CAREERSPEAK_SYSTEM_REQUIREMENTS.md)
- [Globalization & Localization Requirements](docs/specification/CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md)
- [Spring MVC + Local Headless Piper Worker Architecture](docs/architecture/CAREERSPEAK_TTS_PIPELINE.md)

## Current stage

```text
P0 — System Design
```

Next deliverables:

1. Domain map
2. PostgreSQL ERD
3. Content revision model
4. Localization model
5. Assessment model
6. TTS/job ERD
7. Media model
8. Content manifest/offline pack model
9. API contracts
10. ADR baseline
11. P0 implementation backlog

## Commercial model

Initial strategy:

```text
One-time purchase
No mandatory subscription
No ads
No learner runtime AI/STT/TTS cost
```

The product differentiator is curated English content for IELTS and profession-specific international interviews, supported by reusable tests, multilingual hints and pre-generated audio.
