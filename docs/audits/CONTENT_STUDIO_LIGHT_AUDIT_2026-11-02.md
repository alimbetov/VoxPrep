# Content Studio / B1 — Light Audit 2026-11-02

## Scope

Light consistency audit of:

- `CAREERSPEAK_CONTENT_STUDIO_REQUIREMENTS.md`;
- current CareerSpeak system/product boundaries;
- learner-side optional `coverImage` path;
- PostgreSQL/RustFS operational assumptions for B1.

This is not a redesign. The existing authoring model remains valid.

## Result

Overall assessment: **GOOD / implementation-ready after small hardening additions**.

The original Content Studio specification correctly covers server-rendered MVC, XML validation/diff/apply, immutable published revisions, optimistic locking, auditability and cache invalidation.

The audit found several operational gaps that should be frozen before B1 implementation.

| ID | Gap | Severity | Resolution |
| --- | --- | --- | --- |
| LA-01 | learner supports `coverImage`, but B1 authoring did not define minimal image upload/binding | medium | `CAREERSPEAK_CONTENT_STUDIO_HARDENING_ADDENDUM.md` |
| LA-02 | `/admin/**` had auth+CSRF but session/bootstrap hardening was underspecified | medium | hardening addendum |
| LA-03 | PostgreSQL/RustFS DEV/TEST/PROD topology was not normative | high | `CAREERSPEAK_INFRASTRUCTURE_REQUIREMENTS.md` |
| LA-04 | Backend DB runtime privilege separation was unspecified | high | separate bootstrap/owner/migrator/runtime roles |
| LA-05 | Backend RustFS credential could accidentally become the root credential | high | dedicated bucket-scoped IAM identity |
| LA-06 | secrets/volume naming and PROD isolation were unspecified | high | file-based secret + isolated contour contract |
| LA-07 | backup/restore evidence was not a release qualification | high | backup + clean restore drill acceptance |
| LA-08 | RustFS data-directory UID/permissions were not frozen | medium | deployment verifies UID-compatible ownership |
| LA-09 | dependency health/readiness was implicit | medium | `pg_isready` + RustFS health + Backend readiness |
| LA-10 | version pinning policy was absent | medium | stable explicit tags; digest pinning for PROD |

## Strong decisions retained

No changes are recommended to these existing choices:

```text
Spring Boot modular monolith
Spring MVC + Thymeleaf + HTMX
no separate admin SPA
XML Preview before Apply
single transactional Apply
published revision immutability
MapStruct for structural mapping only
restricted Lombok
Caffeine never used as authoring truth
C4 publication remains the only learner visibility boundary
```

## Infrastructure decision

Do **not** create custom PostgreSQL/RustFS images merely to add configuration.

Use official images with:

```text
version-pinned Compose manifests
mounted initialization scripts
Docker/file secrets
explicit volumes/bind mounts
health checks
separate DEV/TEST/PROD project names
```

A custom thin image is justified only later if packaging init/config assets materially improves deployment reproducibility.

## Production topology decision

The first MVP may operate on a single host only as an explicitly non-HA deployment with tested external backups. This keeps commercial launch simple without pretending one Docker host is highly available.

Production evolution path:

```text
single-host MVP
  ↓ when traffic/availability justify it
external PostgreSQL / replicated DB strategy
  +
RustFS multi-disk or multi-node topology
```

## Security decision

Normal runtime credentials are least-privileged:

```text
PostgreSQL superuser → bootstrap only
Liquibase migrator   → DDL/migrations
Backend DB user      → runtime DML

RustFS root          → bootstrap/break-glass only
Backend RustFS IAM   → bucket/prefix-scoped object access
```

Flutter and TTS Worker continue to have no direct database or RustFS credential path.

## Conclusion

No architectural blocker was found. The missing pieces were mainly operational hardening, not product/domain design.

After adding the two normative documents below, B1 can proceed without opening a new feature stream:

- `CAREERSPEAK_CONTENT_STUDIO_HARDENING_ADDENDUM.md`;
- `CAREERSPEAK_INFRASTRUCTURE_REQUIREMENTS.md`.
