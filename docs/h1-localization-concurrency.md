# H1 — Localization revision concurrency hardening

Branch: `feat/commercial-release`. No additional feature branches or pull requests.

## Root cause

`ContentLocalizationAuthoringService.create` and `createNext` derived the next
localization revision number using a read of the latest existing revision. Concurrent
transactions could compute the same number before either had committed.
The database unique constraint prevented duplicate persisted identities, but the API
could return an unhandled constraint error instead of a valid allocation or managed
version conflict.

## Correction

Both revision-number allocation paths now acquire a PostgreSQL row lock on the
owning `app.content_revision` row with `SELECT ... FOR UPDATE` inside the existing
`@Transactional` boundary, *before* querying the latest localization revision.
The lock is held until commit/rollback, including across separate backend instances.

- Parallel `create` calls serialize and produce consecutive revision numbers.
- Parallel `createNext` calls serialize; the first creates a new draft, and the
  subsequent call detects the now non-latest approved source and returns a
  `ContentAuthoringConflictException` (HTTP 409 through existing MVC advice).
- Database uniqueness remains a final defensive invariant.
- `DataIntegrityViolationException` in the localization persistence boundary is
  converted to a domain-level conflict; a failed transaction still rolls back.

Tradeoff: writes for *different locales of the same content revision* serialize as
well. This deliberately favors correctness and simple lock ordering over throughput;
localization revision creation is an administrative action. Existing draft edits,
review, approval and read queries do not acquire the parent lock.

## Acceptance

`ContentLocalizationConcurrencyIntegrationTest` runs against the actual PostgreSQL
integration database:

1. Concurrent creates produce distinct revision numbers 1 and 2 and two persistent records.
2. Concurrent next-revision attempts against one approved source produce exactly one
   newly persisted draft and one domain conflict, not two drafts.
3. Existing localization authoring and MVC acceptance remain mandatory.

Do not declare H1 closed solely from this slice: content-binding concurrency,
canonical checksums, and authorization remain separate H1 audit items. Require exact
SHA backend CI green before accepting the localization sub-slice.
