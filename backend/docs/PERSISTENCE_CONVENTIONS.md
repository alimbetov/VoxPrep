# B1 Persistence Conventions

Status: normative Backend implementation convention for B1.

This document defines the persistence rules that all CareerSpeak / VoxPrep Backend modules SHALL follow unless a later domain-specific ADR explicitly overrides them.

## 1. Identity

Each persistent aggregate/entity uses two identities where applicable:

- technical primary key: `UUID`;
- stable business identity: immutable `code` represented by `StableCode`.

Technical UUID values are persistence identities and MUST NOT encode business meaning.

Stable codes are opaque and case-sensitive. The Backend MUST NOT silently lowercase, trim, slugify, or otherwise normalize a supplied stable code. Current shared limits are:

- non-null;
- non-blank;
- maximum 128 characters;
- no leading/trailing whitespace;
- no control characters.

A module MAY impose a stricter format if its public contract explicitly requires it.

## 2. Revision identity

Revisioned domain objects use an exact revision identity:

```text
(stableCode, revisionNumber)
```

`revisionNumber` starts at `1`, increments exactly, and is never reused for a different immutable revision.

Published revision identity is therefore never represented only by the UUID primary key.

A future revision table SHALL normally enforce a unique constraint over `(code, revision)` or the equivalent owner/code/revision tuple.

## 3. Lifecycle and availability

Cross-module availability is persisted as a string enum:

```text
ACTIVE | INACTIVE
```

Ordinal enum persistence is forbidden.

Revision lifecycle such as:

```text
DRAFT
READY_FOR_AUDIO
READY_FOR_REVIEW
PUBLISHED
ARCHIVED
```

belongs to the owning module and SHALL also be stored as explicit strings with database constraints where practical.

Published revisions are immutable. A requested change to a published revision creates a new mutable revision; it does not update the published row in place.

## 4. JPA base contract

Entities that use the standard Backend persistence lifecycle extend `AbstractJpaEntity`, which provides:

- UUID primary key generated with JPA `GenerationType.UUID`;
- `@Version` optimistic-lock column;
- immutable `created_at` audit timestamp;
- mutable `updated_at` audit timestamp.

Both timestamps use Java `Instant` and PostgreSQL `timestamp with time zone` (`timestamptz`) semantics. Backend Hibernate JDBC time zone remains UTC.

The base class intentionally does not implement `equals()` or `hashCode()`. Mutable fields MUST NOT participate in entity identity. Domain/value objects may implement value equality separately.

## 5. Optimistic locking

Mutable authoring/draft aggregates MUST use optimistic locking.

A stale writer MUST fail instead of silently overwriting a newer change. Application services should translate the persistence exception into a domain/application conflict response at their boundary.

Published immutable rows should normally not be updated at all except for explicitly modeled archival/availability operations permitted by the owning domain.

## 6. Schema and naming

Application objects live in PostgreSQL schema:

```text
app
```

Liquibase metadata lives separately in:

```text
liquibase
```

Runtime identity `voxprep_backend` has no access to Liquibase metadata and no DDL rights.

Database identifiers use `snake_case`.

Recommended constraint/index names:

```text
pk_<table>
fk_<table>__<referenced_table>
uk_<table>__<business_columns>
ck_<table>__<rule>
ix_<table>__<query_columns>
```

Names must be deterministic and explicit when Liquibase supports it.

## 7. Constraints

Invariants that can be enforced without duplicating complex domain workflow SHOULD be enforced in PostgreSQL as well as in Java. Typical examples:

- `NOT NULL`;
- foreign keys;
- unique business identity;
- enum/status `CHECK` constraints;
- revision `>= 1`;
- non-negative sort/position values;
- exact one-parent/reference constraints when practical.

Database constraints are a last line of integrity defense, not a replacement for domain validation.

## 8. Repository boundary

Spring Data repositories are defined for aggregate roots, not for every table by default.

Application services operate through aggregate/domain repositories. Authoring DTOs, XML DTOs, HTTP DTOs, and publication DTOs are not JPA entities and are not persistence contracts.

Cross-aggregate mutation through cascade persistence is forbidden unless aggregate ownership explicitly requires it.

`CascadeType.REMOVE` across aggregate boundaries is forbidden.

Associations should be explicitly `LAZY` unless a measured use case proves otherwise. Query shape should be controlled with dedicated repository queries/entity graphs rather than global eager loading.

## 9. Liquibase

Hibernate DDL remains:

```text
ddl-auto: validate
```

All schema mutation is owned by Liquibase.

Production change sets use deterministic IDs grouped by implementation slice, for example:

```text
b1-p2-0001-create-vertical
b1-p2-0002-create-learning-goal
```

A committed production change set is immutable. Corrections are made by adding a new change set rather than editing an already-applied migration.

Test-only qualification tables belong only in the TEST changelog and MUST NOT leak into the production master changelog.

## 10. B1-P1 acceptance

B1-P1 is accepted only when the real PostgreSQL TEST contour proves:

- JPA-generated UUID persistence;
- version starts at zero and increments on update;
- `created_at` remains immutable;
- `updated_at` advances on mutation;
- `AvailabilityStatus` is stored as a string;
- stable code survives without silent normalization;
- concurrent stale JPA write is rejected;
- runtime DB role still has no DDL or Liquibase-schema access.

The probe entity/table used for these checks exists only in test sources/test changelog. The first product table remains the next catalogue slice.
