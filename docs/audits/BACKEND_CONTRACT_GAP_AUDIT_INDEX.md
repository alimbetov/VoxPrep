# Backend Contract Gap Audit Index

This index links the current backend-contract gap audit workstreams and their remediation plans.

## UI / Motion boundary

See:

- `BACKEND_CONTRACT_GAP_AUDIT_MOTION_PLAN.md`

This audit block records presentation-layer motion gaps discovered while reviewing the learner application. The findings are intentionally tracked from the backend-contract gap branch because backend-delivered state must remain render-safe and deterministic, but the remediation itself belongs to Flutter presentation infrastructure.

### Implementation order

```text
P2 production foundation accepted
        ↓
P3.0 Motion contract
        ↓
P3.1 Navigation motion
        ↓
P3.2 Shared component motion
        ↓
P3.3 Learn + content detail
        ↓
P3.4 Home
        ↓
P3.5 Tests + review
        ↓
P3.6 Motion qualification
```

### Non-negotiable boundary

Motion must not change backend API contracts, sync correctness, Drift CURRENT semantics, installation bootstrap, offline recovery, or audio correctness. It renders state only.

### Acceptance policy

No motion slice is accepted without:
- reduced-motion coverage;
- compact/medium/large qualification;
- full existing production/recovery regression suite;
- renderer/screenshot evidence where appropriate;
- exact-SHA green CI.
