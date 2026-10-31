# Backend Contract Gap Audit Index

This index links the current Flutter ↔ Backend contract-gap audit, the supplemental motion findings, and the consolidated remediation roadmap.

## Primary contract-gap audit

See:

- `docs/backend/FLUTTER_BACKEND_CONTRACT_GAP_AUDIT.md`

Primary backend-owned gaps:

```text
GAP-01 PracticeTest production contract
GAP-02 first-class taxonomy catalog
GAP-03 backend-owned supported locale catalog
GAP-04 learner-facing TTS voice/accent availability
GAP-05 backend entities must not mirror Flutter DTOs
GAP-06 stable codes vs labels separation
GAP-07 revisionable/cacheable product catalogs
GAP-08 learner-state ownership boundary
GAP-09 explicit enum/catalog classification
```

## Supplemental UI / Motion boundary audit

See:

- `docs/audits/BACKEND_CONTRACT_GAP_AUDIT_MOTION_PLAN.md`

The motion audit records presentation-layer gaps discovered while reviewing the learner application. These findings are tracked here because backend-delivered state must remain render-safe and deterministic, but their remediation belongs exclusively to Flutter presentation infrastructure.

Key motion findings:

```text
MOTION-GAP-001 centralized motion contract missing
MOTION-GAP-002 route transitions not explicitly owned
MOTION-GAP-003 adaptive shell child replacement abrupt
MOTION-GAP-004 Learn detail-pane replacement abrupt
MOTION-GAP-005 ContentCard selected state abrupt
MOTION-GAP-006 favorite feedback missing
MOTION-GAP-007 learner marker transitions missing
MOTION-GAP-008 Home stats/progress jump
MOTION-GAP-009 audio state transitions missing
MOTION-GAP-010 practice-test transitions abrupt
MOTION-GAP-011 reduced-motion contract missing
MOTION-GAP-012 motion must not alter production semantics
MOTION-GAP-013 avoid unnecessary third-party animation dependencies
MOTION-GAP-014 Hero transitions premature
MOTION-GAP-015 Settings motion should remain restrained
```

## Consolidated remediation roadmap

See:

- `docs/backend/FLUTTER_BACKEND_CONTRACT_GAP_REMEDIATION_PLAN.md`

Overall implementation order:

```text
B0.1 Content / Manifest baseline ✅
        ↓
B0.2 PracticeTest contract
        ↓
B0.3 Taxonomy contract
        ↓
B0.4 Locale / TTS voice catalog
        ↓
B0.5 Backend aggregate/entity design
        ↓
Backend implementation

P2 production/recovery accepted
        ↓
P3.0 Motion contract
        ↓
P3.1 Navigation motion
        ↓
P3.2 Shared component motion
        ↓
P3.3 Learn + content + audio motion
        ↓
P3.4 Home motion
        ↓
P3.5 Tests + review motion
        ↓
P3.6 Motion qualification
```

## Non-negotiable boundary

Motion must not change:
- backend API contracts;
- sync correctness;
- Drift CURRENT semantics;
- installation bootstrap;
- offline/restart recovery;
- asset verification/repair;
- audio correctness.

Motion renders already-resolved state only.

## Acceptance policy

No remediation slice is accepted without its relevant qualification evidence. For Flutter motion slices this includes:
- reduced-motion coverage;
- compact/medium/large qualification;
- full existing production/recovery regression suite;
- renderer/screenshot evidence where appropriate;
- exact-SHA green CI.
