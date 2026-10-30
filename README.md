# CareerSpeak

**CareerSpeak** is a mobile learning application for IELTS preparation and professional English/job interview training.

Repository codename: **VoxPrep**.

## Product loop

```text
LEARN → LISTEN → REPEAT → TEST → REVIEW
```

The product is designed as a low-runtime-cost, content-driven platform with pre-recorded audio, curated learning content, profession-specific interview preparation and reusable mock tests.

## MVP domains

- IELTS Vocabulary, collocations and contextual examples
- IELTS Speaking and IELTS-style Mock Tests
- English Topics and Shadowing
- General / HR / Behavioral / STAR interviews
- Profession-specific interview tracks
- Reusable Question Bank and Practice Tests
- Favorites, progress and review
- Offline content packs
- Python Moderator Desktop

## Architecture

Initial target stack:

- Flutter — mobile application
- Python + PySide6 — moderator desktop
- Java 21 + Spring Boot — backend
- Spring Cloud Gateway
- Eureka
- PostgreSQL
- RustFS (S3-compatible object storage)
- Liquibase
- Docker
- DigitalOcean production infrastructure

The initial architecture uses the following logical bounded contexts:

```text
IDENTITY
CONTENT
ASSESSMENT
MEDIA
```

## Specification

The architecture and system requirements baseline is maintained here:

[`docs/specification/CAREERSPEAK_SYSTEM_REQUIREMENTS.md`](docs/specification/CAREERSPEAK_SYSTEM_REQUIREMENTS.md)

Current specification version: **0.2**.

## Current status

```text
P0 — Foundation / System Design
```

Next design deliverables:

1. C4 System Context diagram
2. C4 Container diagram
3. Bounded Context Map
4. PostgreSQL ERD
5. Device Auth sequence
6. Content Publishing sequence
7. File upload/download sequence
8. Mock Test execution sequence
9. Offline synchronization sequence
10. Initial OpenAPI contracts
11. ADR baseline
12. P0 implementation backlog

## Commercial model

Initial product strategy: one-time paid application, no mandatory subscription and no mandatory AI/STT/TTS runtime cost per user.
