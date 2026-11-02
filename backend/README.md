# VoxPrep Backend

Spring Boot modular-monolith foundation for CareerSpeak / VoxPrep.

## Runtime baseline

- Java 21
- Spring Boot 4.1.2
- Spring MVC
- Spring Data JPA / Hibernate
- PostgreSQL 18
- Liquibase
- Actuator
- AWS SDK v2 S3 client against private RustFS

## Security boundaries

Backend runtime and migration identities are intentionally separate:

```text
voxprep_backend  -> runtime DML only in app schema
voxprep_migrator -> Liquibase DDL/migrations
voxprep_owner    -> NOLOGIN owner role
```

Liquibase metadata is stored in the separate `liquibase` schema. The runtime role has no access to it.

RustFS credentials are also split:

```text
RustFS root credential -> bootstrap/break-glass only
Backend IAM credential -> private bucket-scoped S3 access
```

The Backend never imports PostgreSQL bootstrap or RustFS root credentials.

## Persistence foundation

B1 persistence conventions are defined in [`docs/PERSISTENCE_CONVENTIONS.md`](docs/PERSISTENCE_CONVENTIONS.md).

The shared production baseline now includes:

```text
StableCode            -> opaque immutable business code policy
RevisionNumber        -> exact 1-based revision identity component
AvailabilityStatus    -> ACTIVE | INACTIVE
AbstractJpaEntity     -> UUID + optimistic version + Instant audit timestamps
```

Product-domain tables are intentionally not created by the B1-P1 foundation slice. JPA/auditing/locking semantics are qualified against a TEST-only table before the first real catalogue aggregate is introduced.

## Secrets

Spring Boot imports a Backend-only configuration tree. Expected keys:

```text
postgres_backend_password
postgres_migrator_password
rustfs_backend_access_key
rustfs_backend_secret_key
```

`infra/scripts/init-secrets.*` creates a restricted Backend projection under:

```text
infra/secrets/<environment>/backend/
```

No production secret has an application default.

## DEV startup

From the repository root:

```bash
./infra/scripts/init-secrets.sh dev

docker compose \
  --env-file infra/env/dev.env.example \
  -f infra/compose/compose.dev.yml \
  up -d --wait postgres rustfs

docker compose \
  --env-file infra/env/dev.env.example \
  -f infra/compose/compose.dev.yml \
  run --rm rustfs-bootstrap

cd backend
mvn -B -ntp spring-boot:run -Dspring-boot.run.profiles=dev
```

The `dev` profile imports `../infra/secrets/dev/backend/`, connects to PostgreSQL on `127.0.0.1:5432` and RustFS on `127.0.0.1:9000`.

## TEST acceptance

GitHub Actions starts the real TEST PostgreSQL/RustFS contour and runs:

```bash
mvn -B -ntp -f backend/pom.xml verify
```

Acceptance verifies:

- Liquibase uses `voxprep_migrator`;
- application runtime uses `voxprep_backend`;
- runtime cannot create tables;
- runtime cannot read Liquibase metadata;
- runtime can use migration-created application tables;
- UUID/version/audit JPA conventions work against PostgreSQL;
- stale JPA writers fail through optimistic locking;
- Backend IAM can put/get/delete a RustFS object;
- readiness is `UP` only when PostgreSQL and RustFS are reachable.

## Health semantics

```text
/actuator/health/liveness  -> process/application state only
/actuator/health/readiness -> readinessState + PostgreSQL + RustFS
```

External dependency failure must not be treated as a liveness failure, preventing orchestration restart loops.
