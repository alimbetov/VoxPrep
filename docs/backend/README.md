# CareerSpeak Backend Documentation

## Canonical v1 documentation

All new backend design work MUST start from:

[`docs/backend/v1/README.md`](v1/README.md)

The canonical v1 set is intentionally compact and ordered:

```text
v1/
├── README.md
├── 01_SYSTEM_ARCHITECTURE.md
├── 02_DOMAIN_MODEL.md
├── 03_LEARNER_API_CONTRACT.md
├── 04_PUBLICATION_AND_INTEGRITY.md
├── 05_SECURITY_AND_MEDIA.md
├── 06_TTS_AND_OPERATIONS.md
└── 07_ACCEPTANCE_AND_IMPLEMENTATION_PLAN.md
```

If a root-level historical backend document conflicts with `docs/backend/v1/`, **the v1 document wins**.

## Legacy material

Existing root-level documents are retained temporarily for:

```text
historical rationale
old qualification evidence
detailed implementation notes
previous gap analysis
traceability from old PRs/commits
```

They are not the preferred backend design entry point anymore.

Examples include:

```text
FLUTTER_BACKEND_CONTRACT_GAP_AUDIT.md
FLUTTER_BACKEND_CONTRACT_GAP_REMEDIATION_PLAN.md
C4_IMPLEMENTATION_ROADMAP.md
C4_IMPLEMENTATION_SLICE_01_PUBLICATION_FOUNDATION.md
qualification ledgers
older freeze/roadmap documents
```

## Removal policy

Do not bulk-delete old docs immediately.

Safe cleanup sequence:

```text
1. canonical v1 set complete
2. update active internal references to v1
3. identify still-useful appendices/fixtures
4. move historical narrative into docs/backend/archive/
5. verify no active contract depends on archived paths
6. remove only true duplicates
```

This gives backend developers one clean source of truth without losing architectural history or breaking repository references.

## Current readiness

```text
Flutter consumer contract              FROZEN enough for backend design
Backend architecture/domain design     READY
Database schema design                 READY
Learner OpenAPI v1                     NEXT DESIGN OUTPUT
Spring Boot implementation             separate next stream
Cross-system acceptance                required before release
```

Do not add Spring Boot implementation code to `feat/flutter-adversarial-hardening`; this branch remains Flutter/contract hardening.