# 07 — Backend Implementation and Acceptance Plan

**Status:** EXECUTION PLAN DERIVED FROM FROZEN CONTRACTS

## 1. Design output before coding deeply

Before broad controller/entity implementation, produce:

```text
1. module dependency diagram
2. PostgreSQL logical ER model
3. immutable revision strategy
4. PublicationSnapshot transaction design
5. installation token verifier/storage design
6. FileAsset + RustFS storage model
7. learner-api-v1 OpenAPI
8. producer contract fixtures matching Flutter decoders
9. TTS lease/uniqueness transaction rules
10. migration/seed strategy
```

## 2. Recommended implementation order

```text
B0  project/module foundation + contract-test harness
B1  installation security
B2  immutable catalogue/content/assessment revision model
B3  universal Vertical catalogue persistence
B4  PublicationSnapshot + atomic CURRENT pointer
B5  root/pack/catalogue/content/assessment learner APIs
B6  localization
B7  FileAsset + Backend media streaming through RustFS
B8  Admin authoring/review/publication
B9  TTS domain + Worker API + output finalization
B10 cross-system acceptance
```

Do not postpone publication architecture until after content tables are fixed; immutable revision/publication identity must shape the schema from the beginning.

## 3. B0 — foundation

Target:

```text
one Spring Boot modular monolith
PostgreSQL
Liquibase
module boundaries
shared contract/error primitives
contract fixture tests
```

No learner business feature should bypass module boundaries by directly reading another module repository.

## 4. B1 — installation security acceptance

Prove:

```text
new random installationId can register
same installationId gets fresh token on next bootstrap
old token is rejected after rotation according to chosen verifier policy
REVOKED installation cannot obtain replacement credential
plaintext token is not logged/persisted unsafely
registration is replay-safe
rate limiting works
```

## 5. B2/B3 — revision/catalogue acceptance

Prove:

```text
stable codes are unique
published revision cannot be mutated
new edit creates new revision
Vertical → Goal → Track → Collection topology validates
invalid/dangling parent relation cannot be published
duplicate/order ambiguity is rejected
exact old revision remains readable
```

## 6. B4 — publication acceptance

Highest-priority transaction tests:

```text
publication candidate validation failure leaves old CURRENT
failure after snapshot insert but before CURRENT switch rolls back
concurrent publishers cannot receive same contentVersion
concurrent publishers cannot mix refs
one contentVersion cannot map to two checksums
CURRENT points to one immutable complete snapshot
all exact refs resolve
```

## 7. B5/B6 — learner contract acceptance

Use shared fixtures to prove responses match Flutter expectations:

```text
GET root 200
GET root 304 with validator
304 without validator never emitted
future/unsupported schema behavior explicit
complete manifest v2 catalogue membership
exact pack identity
exact catalogue identity/checksum
exact canonical content identity/checksum
exact localized content identity/checksum
PracticeTest exact QuestionRevision graph
unknown/malformed contract data rejected by producer tests
```

## 8. B7 — media acceptance

Prove:

```text
valid published asset streams through Backend
Flutter/consumer never receives RustFS URL/credentials
forbidden unpublished asset denied
missing asset 404
not-ready asset 409
RustFS outage gives safe transient failure
byte size/checksum metadata matches object
no redirect to object storage
```

## 9. B8 — admin acceptance

Admin operations must demonstrate:

```text
authoring does not mutate published revision
review/publish transitions validated
invalid catalogue/content graph cannot publish
asset/TTS readiness rules enforced
admin security isolated from installation security
```

## 10. B9 — TTS acceptance

Concurrency/adversarial cases:

```text
two Workers cannot own same live lease
expired lease becomes reclaimable
stale Worker completion rejected
heartbeat extends only current lease
fail/complete replay deterministic
same generation fingerprint does not corrupt current audio association
RustFS write failure cannot mark job READY
READY FileAsset resolves exact stored bytes
```

## 11. B10 — cross-system acceptance

Required Flutter ↔ Backend scenarios:

```text
A01 fresh installation bootstrap
A02 publication N initial sync
A03 publication N → N+1 atomic upgrade
A04 interrupted N+1 sync preserves N
A05 corrupt/missing candidate preserves N
A06 restart after failed sync recovers deterministic CURRENT
A07 locale switch preserves canonical identity
A08 exact assessment offline/restart
A09 media download + checksum verification
A10 local media works while Backend offline
A11 401 → one credential re-issue → one safe retry
A12 repeated 401 fails closed without learner-state loss
A13 deactivation/tombstone removes projection but preserves learner history
A14 unsupported future schema preserves last compatible CURRENT
A15 TTS-generated READY asset enters learner delivery only through publication
```

## 12. Contract CI

Backend CI should include a dedicated contract gate before integration tests:

```text
OpenAPI validation
shared JSON fixtures
canonical checksum vectors
error envelope tests
publication transaction tests
installation security tests
media authorization tests
TTS lease concurrency tests
```

Flutter and Backend should share fixture files or reproducible vectors rather than duplicate examples manually.

## 13. Quality gate for backend-ready PR

A backend PR affecting external contract is not ready unless:

```text
unit/domain tests                GREEN
repository/integration tests     GREEN
contract fixture tests           GREEN
Liquibase migration test         GREEN
publication concurrency tests    GREEN when relevant
security/adversarial tests       GREEN when relevant
OpenAPI updated                  YES when wire contract changes
```

## 14. Change control

If implementation reveals a genuine mismatch with Flutter:

```text
prove incompatibility
→ document proposed contract version change
→ update producer + consumer fixtures
→ update Flutter/backend together
→ only then change behavior
```

Do not silently change v1 behavior to fit a convenient database/JPA model.

## 15. Ready-to-start verdict

```text
Backend architecture/domain design    GO
Database schema design                 GO
Learner OpenAPI v1 finalization        GO
Spring Boot implementation             GO only in a separate backend stream
Cross-system production acceptance     REQUIRED before release
```

The `feat/flutter-adversarial-hardening` branch remains a Flutter/contract hardening branch and should not acquire Spring Boot implementation code.