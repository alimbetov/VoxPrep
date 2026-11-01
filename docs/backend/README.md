# CareerSpeak Backend Documentation Index

**Status:** authoritative navigation for backend design.

Start backend design here:

1. [`BACKEND_DESIGN_BASELINE_V1.md`](BACKEND_DESIGN_BASELINE_V1.md)
2. [`../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`](../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md)
3. [`C4_ATOMIC_PUBLICATION_CONTRACT.md`](C4_ATOMIC_PUBLICATION_CONTRACT.md)
4. [`C5_INSTALLATION_EXTERNAL_SECURITY_CONTRACT.md`](C5_INSTALLATION_EXTERNAL_SECURITY_CONTRACT.md)
5. [`C5_MEDIA_SECURITY_CONTRACT.md`](C5_MEDIA_SECURITY_CONTRACT.md)
6. [`C1_LOCALIZATION_FALLBACK_CONTRACT.md`](C1_LOCALIZATION_FALLBACK_CONTRACT.md)
7. [`C2_TYPED_CONTENT_CATALOG_CONTRACT.md`](C2_TYPED_CONTENT_CATALOG_CONTRACT.md)
8. [`C3_ASSESSMENT_CONTRACT.md`](C3_ASSESSMENT_CONTRACT.md)
9. [`UNIVERSAL_VERTICAL_CATALOGUE_CONTRACT_FREEZE_V1_1.md`](UNIVERSAL_VERTICAL_CATALOGUE_CONTRACT_FREEZE_V1_1.md)
10. TTS contracts and worker integration documents.

## Document classes

### Normative design inputs

These documents define what backend design MUST preserve:

- `BACKEND_DESIGN_BASELINE_V1.md`
- `CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`
- C1/C2/C3/C4/C5 focused contracts
- Universal Vertical Catalogue freeze
- TTS Worker auth/integration contracts

### Implementation guidance

These may guide implementation but do not override normative contracts:

- `C4_IMPLEMENTATION_ROADMAP.md`
- `C4_IMPLEMENTATION_SLICE_01_PUBLICATION_FOUNDATION.md`
- `CAREERSPEAK_BACKEND_TTS_REQUIREMENTS.md`
- `CONTENT_AUDIO_ROLE_POLICY.md`

### Historical/audit material

These explain previous gaps and decisions. They are **not** the current source of truth when they conflict with frozen contracts:

- `FLUTTER_BACKEND_CONTRACT_GAP_AUDIT.md`
- `FLUTTER_BACKEND_CONTRACT_GAP_REMEDIATION_PLAN.md`
- qualification ledgers and historical roadmaps

## Backend design rule

Do not infer backend domain ownership from Flutter persistence tables.

Flutter tables are local projections and learner state. Backend schema must be designed from business ownership and immutable publication contracts:

```text
Catalogue / Content / Assessment
        ↓
immutable revisions
        ↓
PublicationSnapshot
        ↓
learner exact-read API
        ↓
Flutter local CURRENT projection
```

## Current readiness

```text
Backend architecture/domain/schema design   READY
Learner OpenAPI finalization                 NEXT DESIGN OUTPUT
Spring Boot implementation                   NOT STARTED HERE
Cross-system acceptance                      AFTER backend implementation
```

The baseline deliberately keeps Spring Boot implementation out of `feat/flutter-adversarial-hardening`; this branch freezes the consumer-facing contracts first.