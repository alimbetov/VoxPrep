# CareerSpeak

**CareerSpeak** is a global mobile learning application for IELTS preparation and professional English/job interview training.

Repository codename: **VoxPrep**.

## Product loop

```text
LEARN → LISTEN → REPEAT → TEST → REVIEW
```

The product is designed as a low-runtime-cost, content-driven platform with pre-recorded English audio, curated learning content, profession-specific interview preparation and reusable mock tests.

## MVP domains

- IELTS Vocabulary, collocations and contextual examples
- IELTS Speaking and IELTS-style Mock Tests
- English Topics and Shadowing
- General / HR / Behavioral / STAR interviews
- Profession-specific interview tracks
- Reusable Question Bank and Practice Tests
- Favorites, progress and review stored locally by default
- Offline content packs
- Python Moderator Desktop

## Globalization model

CareerSpeak teaches **English**. Other supported languages are used for:

- application UI;
- vocabulary translation;
- localized hints;
- localized explanations and supporting guidance.

Initial locales:

```text
en  English
ru  Russian
kk  Kazakh
```

Planned expansion includes Uzbek, Kyrgyz, Ukrainian, Turkish, Spanish, Portuguese, Hindi, Urdu, Arabic, Bengali, Indonesian, Vietnamese, French and German.

The application does not require GPS solely to select a locale. Locale selection is based on explicit app settings and OS locale/region with English fallback.

## Privacy model

CareerSpeak does not require a personal learner account.

A random technical `installationId` may be generated for security, entitlement and API abuse protection. It is not derived from hardware identifiers and is not used to build a server-side learning profile.

Learning history, favorites, test results, review state and preferences are local-first.

## Architecture

Initial target stack:

- Flutter — mobile application
- Python + PySide6 — moderator desktop
- Java 21 + Spring Boot — backend
- PostgreSQL
- RustFS — S3-compatible media origin
- CDN/edge layer for global audio delivery
- Liquibase
- Docker
- DigitalOcean production infrastructure

The MVP backend is planned as a modular Spring Boot application with logical domains:

```text
ADMINISTRATION
LOCALIZATION
CONTENT
ASSESSMENT
MEDIA
INSTALLATION SECURITY
```

Microservice decomposition, Eureka and Spring Cloud Gateway are optional later decisions rather than mandatory MVP infrastructure.

## Specification

Core architecture and product requirements:

[`docs/specification/CAREERSPEAK_SYSTEM_REQUIREMENTS.md`](docs/specification/CAREERSPEAK_SYSTEM_REQUIREMENTS.md)

Globalization, localization and privacy requirements:

[`docs/specification/CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md`](docs/specification/CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md)

Current specification set: **0.3**.

The globalization document is a normative extension of the original v0.2 system-requirements baseline and clarifies that English is the fixed learning language; other languages are presentation/translation locales.

## Current status

```text
P0 — Foundation / System Design
```

Next design deliverables:

1. C4 System Context diagram
2. C4 Container diagram
3. Bounded Context Map
4. PostgreSQL ERD
5. Locale and translation ERD
6. Hint localization model
7. Installation identity/security flow
8. Content Publishing sequence
9. File upload/download sequence
10. Mock Test execution sequence
11. Offline synchronization and locale-delta design
12. Initial OpenAPI contracts
13. ADR baseline
14. P0 implementation backlog

## Commercial model

Initial product strategy: one-time paid application, no mandatory subscription and no mandatory AI/STT/TTS runtime cost per learner.
