# VoxPrep / CareerSpeak Backend v1 — Database and Environment Profiles

**Status:** normative Backend environment/database policy

## 1. Decision

Backend v1 uses:

```text
dev  -> H2
 test -> PostgreSQL
 prod -> PostgreSQL
```

H2 exists for local development speed and simple MVC/CRUD smoke work only. PostgreSQL is the production database semantics and the only accepted database for integration/concurrency qualification.

## 2. Profile layout

Recommended configuration files:

```text
src/main/resources/application.yml
src/main/resources/application-dev.yml
src/main/resources/application-test.yml
src/main/resources/application-prod.yml
```

Secrets are never committed.

Recommended activation:

```text
local developer       SPRING_PROFILES_ACTIVE=dev
CI integration        test profile + PostgreSQL Testcontainers
staging/test deploy   SPRING_PROFILES_ACTIVE=test
production            SPRING_PROFILES_ACTIVE=prod
```

Do not rely on a default profile for deployed environments.

## 3. Common `application.yml`

Common settings should include only profile-independent policy.

Example target shape:

```yaml
spring:
  application:
    name: voxprep-backend
  jpa:
    open-in-view: false
    hibernate:
      ddl-auto: validate
    properties:
      hibernate.jdbc.time_zone: UTC
  liquibase:
    enabled: true
    change-log: classpath:/db/changelog/db.changelog-master.yaml

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      probes:
        enabled: true
```

Exact actuator exposure may be tightened per deployment.

## 4. DEV — H2

### 4.1 Purpose

H2 dev is for:

- quick application start;
- Spring MVC Content Studio development;
- ordinary JPA repository flows;
- authoring CRUD;
- basic validation and publication happy-path smoke tests;
- local model metadata/provisioning flow when external I/O is stubbed/local;
- developer convenience when PostgreSQL is not running.

H2 dev is not accepted for:

- PostgreSQL SQL compatibility proof;
- TTS multi-worker claim concurrency;
- lease/reclaim concurrency;
- advisory locks;
- PostgreSQL-specific indexes/constraints;
- JSONB behavior;
- production transaction/isolation proof;
- migration acceptance.

### 4.2 Recommended datasource

A file-backed H2 database is preferable for manual MVC development because data survives restart.

Example:

```yaml
spring:
  datasource:
    url: jdbc:h2:file:./.data/voxprep-dev;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE
    driver-class-name: org.h2.Driver
    username: sa
    password: ""
  h2:
    console:
      enabled: true
      path: /h2-console
  jpa:
    database-platform: org.hibernate.dialect.H2Dialect
```

`MODE=PostgreSQL` is a development convenience only. It must never be treated as proof that SQL behaves like PostgreSQL.

The H2 console must be enabled only in `dev` and protected from non-local deployment by profile/deployment policy.

### 4.3 Dev TTS job claim

Production Worker claim requires PostgreSQL `FOR UPDATE SKIP LOCKED` and cannot be honestly qualified on H2.

Define an application port, for example:

```text
TtsJobClaimPort
```

Implementations:

```text
H2DevTtsJobClaimAdapter
PostgresTtsJobClaimAdapter
```

`H2DevTtsJobClaimAdapter` may implement deterministic single-process claim semantics sufficient for local end-to-end development. It must be annotated/configured as `dev` only and must never be active in `test` or `prod`.

`PostgresTtsJobClaimAdapter` is authoritative and must implement the frozen atomic claim/reclaim semantics using `FOR UPDATE SKIP LOCKED`.

The two adapters must share domain-level eligibility/lease policy tests where possible; concurrency acceptance runs only against PostgreSQL.

### 4.4 Dev model provisioning lock

H2 may use a process-local lock for `ensure-present` model bootstrap. This is sufficient only because dev is treated as a single Backend process.

Do not emulate distributed safety and call it production-equivalent.

## 5. TEST — PostgreSQL

### 5.1 Automated integration tests

The default automated integration database is PostgreSQL Testcontainers.

Required coverage includes:

- start from empty database;
- apply full Liquibase master changelog;
- JPA mapping validation;
- installation registration idempotency;
- purchase event replay constraints;
- immutable revision uniqueness;
- publication CURRENT switch transaction;
- TTS atomic claim/reclaim concurrency;
- lease expiry behavior;
- model provisioning uniqueness/locking;
- FileAsset finalization;
- API/Worker contract tests.

Tests must not depend on a developer-installed PostgreSQL instance.

### 5.2 Test deployment environment

A deployed shared `test`/staging Backend also uses PostgreSQL and environment-provided credentials.

Example target shape:

```yaml
spring:
  datasource:
    url: ${DB_URL}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
    driver-class-name: org.postgresql.Driver
  jpa:
    database-platform: org.hibernate.dialect.PostgreSQLDialect
  h2:
    console:
      enabled: false
```

Actual credentials are deployment secrets.

## 6. PROD — PostgreSQL

Production requirements:

- PostgreSQL only;
- TLS/network controls according to deployment environment;
- H2 dependency scoped so it is not required by production runtime where practical;
- H2 console disabled;
- Liquibase migration runs in a controlled deployment step or application startup according to deployment policy;
- no `ddl-auto=create|update`;
- backups/restore procedure defined before production release;
- database connection pool configured and monitored;
- UTC server/database semantics;
- transaction failures observable.

Example target shape:

```yaml
spring:
  datasource:
    url: ${DB_URL}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
    driver-class-name: org.postgresql.Driver
  jpa:
    database-platform: org.hibernate.dialect.PostgreSQLDialect
  h2:
    console:
      enabled: false
```

## 7. Liquibase strategy

Use one master changelog as the schema history source of truth.

Recommended structure:

```text
db/changelog/
  db.changelog-master.yaml
  001-foundation.yaml
  002-identity-access.yaml
  003-content-catalogue.yaml
  004-assessment-media.yaml
  005-tts.yaml
  006-publication.yaml
  ...
```

Rules:

1. Common logical tables/constraints should be portable where reasonable.
2. PostgreSQL-specific performance/concurrency DDL may use Liquibase `dbms: postgresql`.
3. H2-only helper changesets may use `dbms: h2`, but must not define product semantics absent from PostgreSQL.
4. PostgreSQL migration from empty DB is the acceptance baseline.
5. Historical production changesets are immutable after release; corrections are new changesets.
6. Do not let Hibernate generate the authoritative schema.

## 8. Schema naming

Preferred database schema:

```text
voxprep
```

Use the same logical schema name in PostgreSQL and H2 where practical so JPA/Liquibase configuration remains close.

If H2 schema handling causes disproportionate friction during early B1, the dev-only schema may temporarily use its default namespace, but test/prod PostgreSQL and Liquibase remain authoritative. Do not distort production DDL merely to satisfy H2.

## 9. PostgreSQL-only capability boundary

Code that requires PostgreSQL semantics must be behind explicit ports/adapters and easy to identify.

Initial known PostgreSQL-specific components:

```text
PostgresTtsJobClaimAdapter
PostgresModelProvisioningLock
Publication/current-pointer locking if native SQL becomes necessary
PostgreSQL-specific indexes/constraints
```

Do not scatter vendor-specific SQL throughout ordinary repositories.

## 10. Transaction/isolation policy

Use Spring transactions explicitly around application use-cases.

Default transaction isolation should remain PostgreSQL default unless a demonstrated invariant requires stronger isolation or explicit locking.

Critical operations:

```text
installation register/re-register
purchase replay + entitlement grant
revision approval/freeze
publication persist + CURRENT pointer switch
TTS claim/reclaim
TTS heartbeat ownership update
TTS output finalization
model provisioning final registration
```

Concurrency-critical repositories must have PostgreSQL integration tests with multiple concurrent transactions/threads.

## 11. Test taxonomy

### Unit

No DB unless required. Domain services/value objects.

### Repository smoke

May run on H2 for fast developer feedback where repository behavior is portable.

### Integration

PostgreSQL Testcontainers mandatory.

### Contract

PostgreSQL + Spring application context; exercises learner/Worker API against real persistence adapters.

### End-to-end

Real PostgreSQL + RustFS + Backend + Flutter/Worker as appropriate.

H2 must never be used for a test labeled PostgreSQL compatibility, TTS concurrency acceptance, migration acceptance or release qualification.

## 12. Testcontainers policy

CI should use a pinned supported PostgreSQL container major version matching production target.

At minimum execute:

```text
Liquibase migrate empty DB
application context start
integration tests
concurrency tests
```

Optional additional migration fixtures may be added after real production versions exist.

## 13. RustFS profiles

Database choice is independent from object storage.

Recommended dev options:

```text
1. local filesystem adapter for fastest authoring UI work, OR
2. local RustFS container for media/TTS development
```

Contract/integration tests that qualify the real storage boundary must use the actual S3-compatible adapter against a controlled test service/container when available.

Test/prod must not expose RustFS credentials to Flutter/Worker.

## 14. TTS model bootstrap by environment

Recommended defaults:

| Profile | Bootstrap mode | External registry | Auto-activate |
|---|---|---|---|
| dev | `ENSURE_PRESENT` or `DISABLED` | allowed for developer use | optional only for known dev seeds |
| test | `DISABLED` by default | no live public network in CI | false |
| prod | `ENSURE_PRESENT` or operator-selected `STRICT` | allowed through controlled egress | false unless seed already fully qualified |

CI model provisioning tests use a fake/local registry response and tiny fixture bytes, never live Hugging Face.

Production seed definitions must pin immutable source revision/tag/commit and are qualified by SHA-256/license review before ACTIVE.

## 15. Example Backend environment variables

Common examples:

```text
SPRING_PROFILES_ACTIVE
SERVER_PORT

DB_URL
DB_USERNAME
DB_PASSWORD

RUSTFS_ENDPOINT
RUSTFS_ACCESS_KEY
RUSTFS_SECRET_KEY
RUSTFS_BUCKET

TTS_WORKER_TOKEN
TTS_LEASE_DURATION_SECONDS
TTS_MAX_ATTEMPTS
TTS_MODEL_BOOTSTRAP_MODE

ADMIN_USERNAME
ADMIN_PASSWORD_HASH or approved equivalent secret
```

When Store verification is implemented:

```text
GOOGLE_PLAY_* server credentials
APPLE_* server credentials
```

Do not commit secret values or put them into Flutter configuration.

## 16. Acceptance matrix

| Capability | H2 dev evidence accepted? | PostgreSQL test required? |
|---|---:|---:|
| MVC CRUD | yes | yes before slice closure |
| JPA basic mapping | yes | yes |
| Liquibase production migration | no | yes |
| publication happy path | smoke only | yes |
| publication concurrent/current switch | no | yes |
| TTS single-process claim | dev smoke only | yes |
| TTS multi-worker claim | no | yes |
| lease reclaim | no | yes |
| provisioning uniqueness | smoke only | yes |
| purchase replay constraint | smoke only | yes |
| release qualification | no | yes |

## 17. Final database invariant

```text
H2 optimizes developer iteration.
PostgreSQL defines Backend persistence truth.
PostgreSQL Testcontainers proves persistence/concurrency behavior before merge.
```
