# CareerSpeak Backend v1 — Canonical Documentation

**Status:** AUTHORITATIVE BACKEND DESIGN SET  
**Source branch:** `feat/flutter-adversarial-hardening`

This directory is the only documentation set that should be used to design the CareerSpeak v1 backend.

Older documents under `docs/backend/` and `docs/architecture/` remain historical/reference material until migration is complete. If an older document conflicts with this directory, **`docs/backend/v1/` wins**.

## Read in this order

1. [`01_SYSTEM_ARCHITECTURE.md`](01_SYSTEM_ARCHITECTURE.md)
2. [`02_DOMAIN_MODEL.md`](02_DOMAIN_MODEL.md)
3. [`03_LEARNER_API_CONTRACT.md`](03_LEARNER_API_CONTRACT.md)
4. [`04_PUBLICATION_AND_INTEGRITY.md`](04_PUBLICATION_AND_INTEGRITY.md)
5. [`05_SECURITY_AND_MEDIA.md`](05_SECURITY_AND_MEDIA.md)
6. [`06_TTS_AND_OPERATIONS.md`](06_TTS_AND_OPERATIONS.md)
7. [`07_ACCEPTANCE_AND_IMPLEMENTATION_PLAN.md`](07_ACCEPTANCE_AND_IMPLEMENTATION_PLAN.md)

## Frozen external contract

Flutter already depends on these semantics:

```text
Vertical → LearningGoal → LearningTrack → LearningCollection
exact immutable revisions/checksums
atomic publication/CURRENT
locale-independent root publication
exact localized payload identity
exact PracticeTest/Question revisions
random installationId + rotating installationToken
Backend-authorized media streaming
RustFS private behind Backend
fail-closed mismatch/corruption handling
learner progress/review/attempt state remains local in Flutter
```

Backend may choose internal table/JPA implementation freely only when these external invariants remain unchanged.

## Backend shape

Recommended v1 deployment unit:

```text
Spring Boot modular monolith
├── PostgreSQL
├── RustFS adapter
├── learner API /api/v1/**
├── admin API /admin/**
└── TTS Worker API /internal/v1/tts/**
```

Do not split publication-critical modules into separate services for v1.

## What this set intentionally excludes

This directory does not define server-side learner accounts or progress because CareerSpeak MVP does not require them.

Explicit non-goals:

```text
learner profile/account service
OAuth/OIDC/Keycloak for learners
refresh-token flow
server-side review scheduler
server-side learner progress
recommendation engine
AI personalization
social/leaderboard domain
remote UI schema
EAV learning-content model
message broker solely for TTS queueing
client-visible RustFS/S3 credentials or URLs
```

## Migration policy for old docs

Old documents are not deleted immediately.

Migration sequence:

```text
v1 canonical set complete
→ internal links updated
→ old docs classified historical vs still-useful appendices
→ historical docs moved to docs/backend/archive/
→ only then remove redundant copies
```

This prevents loss of rationale and broken repository links while still giving backend developers one clear source of truth.