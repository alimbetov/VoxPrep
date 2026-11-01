# CareerSpeak — MVP Functional & Business Sufficiency Audit

**Audit date:** 2026-11-01  
**Status:** Normative reconciliation record for CareerSpeak v1  
**Branch:** `feat/ba-product-contract-remediation`

## 1. Conclusion

The Flutter product/business remediation is **functionally sufficient for merge** once the exact branch revision passes the normal quality/regression gate.

This does **not** mean the complete CareerSpeak MVP is production-ready. The following mandatory delivery stages intentionally remain after this branch:

```text
C4  Atomic Publication
 ↓
C5  Installation / Security
 ↓
B1  Backend schema + modular-monolith implementation
 ↓
A1  Cross-system acceptance
```

No additional Flutter learner-domain feature stream is required before those stages.

## 2. Normative contract precedence

When older planning/backlog documents conflict with the accepted MVP boundary, use this order:

```text
CAREERSPEAK_PRODUCT_REQUIREMENTS.md
        ↓
CAREERSPEAK_MVP_DELIVERY_SCOPE.md
        ↓
accepted focused product contracts
        ↓
SYSTEM / MOBILE requirements
        ↓
implementation roadmaps / historical remediation notes
```

A roadmap is not allowed to re-open a capability explicitly deferred by the normative MVP delivery scope.

## 3. Functional sufficiency matrix

| Capability | MVP decision | Audit status |
|---|---|---|
| Vertical → Goal → Track → Collection | backend-owned, universal hierarchy | sufficient |
| Onboarding | 3 decisions, skippable, account-free, restart-safe | sufficient |
| Learner selection | Goal/Track persisted; Vertical derived; invalid selection fails closed | sufficient |
| Continue Learning | deterministic priority + CURRENT revalidation | sufficient |
| Content completion | explicit learner intent; exact revision history preserved | sufficient |
| PracticeTest | restart-safe active attempt + exact revision completion | sufficient |
| Review / Due | deterministic local scheduler; `nextReviewAt <= now` | sufficient |
| Favorites | durable local marker/filter | sufficient for MVP |
| Standalone Favorites screen | convenience surface | deferred post-MVP |
| Offline content | verified local assets + restart-safe state | required |
| User-managed Downloads screen | convenience/storage management surface | deferred post-MVP |
| Audio | real local asset resolution/playback path | sufficient at Flutter contract level |
| Runtime catalogue source | Backend HTTP + local CURRENT projection | sufficient; demo/mock runtime switching forbidden |
| Atomic CURRENT publication | one coherent publication identity | mandatory C4 |
| Installation token security | installation-scoped auth + bounded 401 recovery | mandatory C5 |
| Backend product implementation | Spring Boot modular monolith | mandatory B1 |
| Backend ↔ Flutter qualification | real publication/sync/offline/restart path | mandatory A1 |

## 4. Business decisions reconciled by this audit

### 4.1 Invalid learner selection is fail-closed

No automatic replacement with an arbitrary sibling is permitted.

```text
Track inactive/missing
→ clear Track
→ preserve active Goal

Goal inactive/missing
→ clear Goal + Track
→ current Vertical becomes unset
→ show Choose learning direction

Vertical inactive/missing
→ selected Goal becomes invalid
→ apply the same Goal rule
```

The application must not silently select the first active Track, Goal or unrelated Vertical.

### 4.2 Vertical is mandatory in the product hierarchy

The only normative learner hierarchy is:

```text
Vertical
 ↓
LearningGoal
 ↓
LearningTrack
 ↓
LearningCollection
 ↓
exact ContentRevision / PracticeTestRevision members
```

Any older `Goal → Track → Collection` hierarchy without Vertical is superseded.

### 4.3 Favorites are a marker, not a mandatory feature stream

MVP requires durable `FAVORITE` state and learner-visible favorite filtering/feedback where the current UI exposes it.

A dedicated `/favorites` application area is not a release gate. It may be added after MVP without changing the learner-state contract.

### 4.4 Downloads are infrastructure-first in MVP

MVP requires:

```text
authorized backend media delivery
→ bounded download
→ checksum/size verification
→ atomic local placement
→ AssetResolver
→ offline playback
```

A dedicated user-managed Downloads screen, collection-level download dashboard, storage chart or manual download library is not an MVP release gate.

Cache/media eviction must never erase learner progress, review, attempts or preferences.

### 4.5 Learner media delivery is Backend-authorized HTTP

For MVP, Flutter communicates only with the Backend learner API boundary. Flutter never owns RustFS/object-storage credentials and never interprets `deliveryKey` as a remote URL.

The accepted production path is:

```text
Flutter installation token
→ authenticated Backend media endpoint/API
→ bytes supplied through Backend-controlled delivery
→ Flutter verifies metadata/checksum
→ verified local asset
```

The Backend may internally use RustFS; that topology is not exposed as a Flutter credential boundary. A future signed-grant model would require a new versioned contract and is not part of CareerSpeak v1.

### 4.6 Runtime demo/mock catalogue switching is not a production contract

Production Flutter catalogue data comes from:

```text
Backend publication/API
→ sync/staging
→ atomic CURRENT projection
→ local repositories/UI
```

Mocks remain test fixtures only.

## 5. Remaining mandatory contract gates

### C4 — Atomic Publication

One publication identity must cover at minimum:

```text
Vertical
Goal
Track
Collection
Content revisions
PracticeTest revisions
Localization
Assets/audio references
```

Required invariants:

- all candidate payloads are validated before activation;
- readers never observe a mixed publication;
- CURRENT changes by one atomic activation boundary;
- an incomplete/corrupt candidate never replaces last-known-good CURRENT;
- restart preserves or deterministically recovers the previous valid CURRENT;
- exact revisions/checksums remain reproducible.

### C5 — Installation / Security

Normative flow:

```text
installationId
→ idempotent registration/re-registration
→ installationToken
→ authorized learner API
```

Credential recovery is bounded:

```text
401
→ invalidate rejected token only
→ preserve installationId + learner state
→ re-register once
→ retry a safe request once where policy permits
→ fail closed on repeated rejection
```

No learner account is introduced.

### B1 — Backend

Use a Spring Boot modular monolith with PostgreSQL and private RustFS integration. Minimum product modules:

```text
installation
catalogue
publication
content
assessment
localization
asset
tts
```

TTS Worker remains a separate computational worker; it does not justify domain microservices.

### A1 — Cross-system acceptance

The release gate must prove the real path:

```text
Backend publication
→ learner HTTP API
→ Flutter sync
→ Drift CURRENT
→ content/audio/test/review
→ offline
→ process restart
```

Acceptance includes stale, corrupt, replay, interruption and exact-revision cases.

## 6. Explicitly deferred product work

The audit does not reopen:

```text
standalone Favorites area
user-managed Downloads dashboard
cloud learner profile/sync
mandatory learner login
AI recommendations/personalization
advanced SRS/FSRS/SM-2
runtime STT/pronunciation scoring
social/leaderboards/badges
analytics platform before telemetry approval
microservices/distributed messaging for learner flows
```

These require separate versioned evidence and requirements after MVP.

## 7. Merge readiness rule for this branch

`feat/ba-product-contract-remediation` is business/functionally merge-ready when:

```text
[✓] product hierarchy is unambiguous
[✓] selection semantics are fail-closed
[✓] onboarding ownership/restart semantics are frozen
[✓] Continue Learning is deterministic
[✓] PracticeTest exact-revision lifecycle is frozen
[✓] Review/Due policy is deterministic and restart-safe
[✓] media boundary is Backend-authorized HTTP
[✓] deferred surfaces do not reopen new Flutter feature streams
[✓] remaining C4/C5/B1/A1 work is explicitly gated
[ ] exact merge-candidate revision passes quality/regression qualification
```

The final unchecked item is an engineering qualification gate, not an unresolved business-analysis requirement.
