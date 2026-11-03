# H1 — Content integrity and security hardening

Branch: `feat/commercial-release`; PR #39. No new branches or pull requests.

## H1.1 Localization revision allocation
- PostgreSQL parent content-revision row lock before localization revision-number allocation.
- Parallel creates serialize; repeated create-next from one approved revision returns a conflict.
- See `docs/h1-localization-concurrency.md`.

## H1.2 Server-owned localization checksum
- Previous REST transport accepted `checksumSha256` and passed its value into the stored localization revision.
- `ContentLocalizationChecksum.compute` uses the six normalized localized text fields in stable order.
- `ContentLocalizationAuthoringService` now computes SHA-256 inside `create`, `updateDraft` and `createNext`; the supplied checksum argument no longer affects persisted data.
- REST accepts legacy `checksumSha256` optionally for compatibility, but ignores it. Future clients should omit it.
- Application integration asserts caller-provided digests do not determine the persisted checksum.

## H1.3 Media binding concurrency
- `ContentAssetBindingService.bind` now acquires the owning `app.content_revision` row lock before checking publication state and reading/replacing or inserting `content_asset_binding`.
- All instances using this service serialize same-content bindings; the unique (content_revision_id, role) constraint remains defense in depth.
- Concurrent insert and replacement tests require one persistent binding per role.
- This does not introduce compare-and-set semantics for editors. Two valid serial replacements are **last-writer-wins**. If the admin UI supports manual media reassignment, expose an expected binding version before considering concurrent editor conflict resolution complete.
- Publication/freeze transactions must be audited separately to ensure lock ordering and race-free published immutability.

## H1.4 Negative security
- Unauthorized Basic API requests must not reach localization mutation.
- Non-admin MVC sessions must not approve localizations.
- MVC POST without CSRF token must be rejected.
- The current admin role remains a coarse privilege; independent reviewer and approver roles plus segregation-of-duties policy are pending review.

## Qualification boundary
Run actual PostgreSQL integration tests and full B1 Backend Foundation on the exact
head SHA. Keep H1 open until those checks are green and unresolved publishing/media
binding and approval-authorization policy risks are explicitly reviewed.

H2 RustFS/recovery must be developed only after the current H1 regression suite is green.
