# CareerSpeak / VoxPrep — Infrastructure Requirements

**Document version:** 1.0  
**Status:** Normative B1 infrastructure baseline  
**Applies to:** CareerSpeak v1 Backend implementation  
**Scope classification:** internal B1 infrastructure; not a separate feature stream or independent MVP release gate

Normative parents:

- [`CAREERSPEAK_SYSTEM_REQUIREMENTS.md`](CAREERSPEAK_SYSTEM_REQUIREMENTS.md)
- [`CAREERSPEAK_MVP_DELIVERY_SCOPE.md`](CAREERSPEAK_MVP_DELIVERY_SCOPE.md)
- [`CAREERSPEAK_CONTENT_STUDIO_REQUIREMENTS.md`](CAREERSPEAK_CONTENT_STUDIO_REQUIREMENTS.md)
- [`../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`](../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md)

---

## 1. Purpose

B1 SHALL provide a repeatable containerized infrastructure baseline for PostgreSQL and RustFS so that Backend development, automated qualification and the first production deployment use the same logical topology and security model.

Required contours:

```text
DEV
TEST
PROD
```

The contours MUST use isolated data, credentials, networks and storage paths. A DEV or TEST reset command MUST NOT be able to target PROD by default.

---

## 2. Image strategy

Do not build custom database/object-storage images unless a concrete requirement appears.

Baseline images:

```text
PostgreSQL: official postgres image, stable PostgreSQL 18 line
RustFS:     official rustfs/rustfs stable 1.0.x line
```

Initial implementation target at the time this document was written:

```text
postgres:18.6-bookworm
rustfs/rustfs:1.0.4
```

Rules:

- PROD SHALL pin explicit image versions and SHOULD pin immutable digests in the deployment manifest;
- PROD SHALL NOT use `latest`;
- DEV/TEST SHOULD use the same major/minor product versions as PROD unless compatibility testing intentionally varies them;
- image upgrades require backup/restore verification and the normal qualification suite;
- PostgreSQL 19 pre-release/RC images are not part of the v1 production baseline.

A thin derived image MAY later be introduced only to package stable initialization assets. Mounting versioned init scripts/configuration from the repository is preferred for v1.

---

## 3. Required repository layout

The B1 implementation SHOULD materialize this layout or an equivalent one:

```text
infra/
  compose/
    compose.dev.yml
    compose.test.yml
    compose.prod.yml

  env/
    dev.env.example
    test.env.example
    prod.env.example

  postgres/
    init/
      00-bootstrap.sh
    README.md

  rustfs/
    bootstrap/
      bootstrap.sh
    policies/
      backend-rw.json
    README.md

  secrets/
    README.md

  README.md
```

Real secret files SHALL NOT be committed.

---

## 4. Network boundary

Production default:

```text
Internet
   ↓
Reverse proxy / TLS
   ↓
Spring Boot Backend
   ├── PostgreSQL private network
   └── RustFS private network
```

PostgreSQL and the RustFS S3 endpoint SHALL NOT be internet-facing.

The RustFS Console SHALL NOT be publicly exposed in PROD. It may be bound to localhost, an administration network or disabled when not required.

DEV may expose convenience ports only on loopback, for example:

```text
127.0.0.1:5432 → PostgreSQL
127.0.0.1:9000 → RustFS S3 API
127.0.0.1:9001 → RustFS Console
```

TEST used by CI SHOULD prefer an isolated Docker network without host port publication unless the test runner requires it.

---

## 5. PostgreSQL topology

Logical databases:

```text
DEV  → voxprep_dev
TEST → voxprep_test
PROD → voxprep
```

The application schema SHOULD be named explicitly, for example:

```text
app
```

PostgreSQL data persistence:

```text
DEV  → named Docker volume
TEST → isolated named/ephemeral CI volume
PROD → durable host/block-storage-backed volume
```

For PostgreSQL 18+, the persistent mount SHALL follow the official image layout and mount `/var/lib/postgresql`, with version-specific `PGDATA` handled consistently by the image/configuration.

Recommended PROD host layout:

```text
/srv/voxprep/prod/postgres/
  data/
  backup/
```

A Docker volume is persistence, not a backup.

---

## 6. PostgreSQL role model

The Spring Boot Backend MUST NOT connect as the PostgreSQL superuser.

Minimum roles:

```text
postgres/bootstrap administrator
  ↓ only container/bootstrap/maintenance

voxprep_owner
  ↓ NOLOGIN owner of application schema/objects

voxprep_migrator
  ↓ LOGIN used by Liquibase

voxprep_backend
  ↓ LOGIN runtime Backend role
```

Rules:

- `voxprep_backend` receives only the DML/sequence privileges required at runtime;
- `voxprep_backend` MUST NOT own the database or application schema;
- `voxprep_migrator` receives the DDL privileges needed by Liquibase and is not used by normal request processing;
- bootstrap/superuser credentials are never supplied to the Backend runtime;
- DEV/TEST/PROD use separate passwords even when role names are identical;
- destructive test privileges exist only in TEST/DEV.

Spring Boot SHOULD use separate datasource/Liquibase credentials where practical:

```text
spring.datasource.* → voxprep_backend
spring.liquibase.*  → voxprep_migrator
```

---

## 7. PostgreSQL initialization

The official PostgreSQL image initialization boundary MAY use version-controlled `*.sh` / `*.sql` scripts mounted under:

```text
/docker-entrypoint-initdb.d
```

Initialization SHALL be idempotent at the logical level and SHALL account for the fact that the official image executes init scripts only for a new/empty data directory.

The bootstrap script SHALL create/grant only the expected database, schema and roles.

Schema evolution after first initialization belongs to Liquibase, not to repeated container bootstrap scripts.

---

## 8. RustFS topology

RustFS stores private Backend binary objects. Flutter and TTS Worker do not receive direct RustFS credentials.

DEV/TEST baseline:

```text
single RustFS node
persistent isolated volume
```

This is sufficient for local/qualification workloads.

PROD v1 may start as a single-host deployment only when explicitly accepted as a non-HA MVP topology with tested backups. The preferred durable production direction is RustFS multi-disk/multi-node deployment when availability requirements justify it.

Recommended PROD host layout for a single-host MVP:

```text
/srv/voxprep/prod/rustfs/
  data/
  logs/
  backup/
```

RustFS bind-mounted data/log paths SHALL have permissions compatible with the container runtime user. Current official containers use RustFS UID `10001`; the deployment bootstrap SHALL verify ownership before startup.

---

## 9. RustFS credentials and IAM

RustFS root credentials are bootstrap/break-glass credentials only.

Required split:

```text
RUSTFS root credential
  ↓ bootstrap / emergency administration only

voxprep-backend IAM user/service credential
  ↓ normal Spring Boot object access
```

The Backend MUST NOT use the RustFS root access key/secret during normal operation.

The Backend credential SHALL be scoped to the required VoxPrep bucket(s)/prefixes and SHALL NOT receive IAM administration, console administration or unrestricted cluster administration permissions.

V1 SHOULD use a bucket-scoped read/write policy for the Backend.

The bootstrap process SHOULD create, if absent:

```text
bucket(s)
backend IAM user/service account
backend bucket-scoped policy
policy attachment
```

The bootstrap process must be replay-safe.

---

## 10. RustFS buckets / prefixes

Keep v1 simple. A single private bucket with explicit prefixes is acceptable:

```text
voxprep-assets/
  content/
  cover/
  audio/
  tts-model/
  staging/
```

Equivalent separate buckets MAY be used if retention/security requirements require them, but bucket proliferation is not an MVP goal.

Rules:

- learner media is never public;
- object keys are internal storage metadata, not learner URLs;
- published object metadata in PostgreSQL includes integrity information required by existing contracts;
- staging objects are never learner-visible;
- physical deletion SHALL be conservative enough not to invalidate retained database backups/publication history.

---

## 11. Secrets model

Real credentials SHALL NOT be committed to Git or baked into Docker images.

Preferred injection is file-based Docker secrets/config-tree compatible mounts.

Examples of secret classes:

```text
postgres bootstrap password
postgres migrator password
postgres backend password
RustFS root access key
RustFS root secret key
RustFS backend access key
RustFS backend secret key
ADMIN credential/password material
worker token signing/credential material where applicable
```

PROD example host location:

```text
/etc/voxprep/secrets/prod/
```

Secret files SHOULD be owner-readable only (`0600` or equivalent).

Repository `.env.example` files contain names/placeholders only, never usable production secrets.

Spring Boot MAY consume mounted secret files through Spring Boot config tree or an equivalent explicit file-based configuration boundary.

---

## 12. DEV / TEST / PROD isolation

Required namespacing:

```text
DEV  project/network/volumes/secrets ≠ TEST
TEST project/network/volumes/secrets ≠ PROD
PROD project/network/volumes/secrets ≠ DEV
```

Recommended Compose project names:

```text
voxprep-dev
voxprep-test
voxprep-prod
```

Recommended Docker volume names:

```text
voxprep_dev_pgdata
voxprep_dev_rustfs_data
voxprep_dev_rustfs_logs

voxprep_test_pgdata
voxprep_test_rustfs_data
voxprep_test_rustfs_logs
```

PROD SHOULD use explicit durable bind mounts or externally managed named volumes rather than anonymous volumes.

`docker compose down -v` MUST be documented as DEV/TEST-only. Production runbooks SHALL NOT include it as a normal operation.

---

## 13. Health and readiness

Compose/runtime health checks SHALL cover at least:

```text
PostgreSQL → pg_isready
RustFS     → /health or equivalent readiness endpoint
Backend    → Spring Boot readiness/Actuator boundary
```

Backend startup SHALL fail clearly when required persistent dependencies are unavailable; it SHALL NOT silently create a second local persistence path.

The application should distinguish dependency liveness from migration/readiness.

---

## 14. Backup and restore

Persistence without restore evidence is insufficient for PROD acceptance.

Minimum v1 production backup baseline:

```text
PostgreSQL logical backup
RustFS data backup/snapshot
secret/config backup under separate protected procedure
```

Requirements:

- backups are stored outside the active container volumes;
- backup retention is documented;
- at least one restore drill is completed before production acceptance;
- restore uses a clean target, not the active PROD data directory;
- restored PostgreSQL and RustFS data are checked for referential/integrity consistency;
- an object referenced by a retained publication/database backup must not be physically deleted before the corresponding retention window expires.

Recommended first MVP policy:

```text
daily backup
+ pre-deployment backup
+ periodic restore drill
```

Exact RPO/RTO may be tightened after real usage data exists.

---

## 15. Production TLS and exposure

External Backend traffic SHALL use TLS.

RustFS S3/Console traffic outside a trusted single-host Docker network SHALL use TLS with certificate verification. Disabling TLS verification is DEV-only.

PostgreSQL exposure outside the private deployment network is prohibited by default.

---

## 16. Observability and logs

At minimum collect/preserve:

```text
Backend application logs
PostgreSQL operational logs
RustFS operational logs
backup/restore job result
container restart/health state
```

Secrets, database passwords, RustFS secret keys and authorization headers MUST NOT appear in logs.

RustFS logs SHOULD use a persistent log path in PROD or be collected by the host logging driver.

---

## 17. Required implementation artifacts

B1 infrastructure implementation SHALL eventually provide:

```text
compose.dev.yml
compose.test.yml
compose.prod.yml
example environment files
secret handling README
PostgreSQL bootstrap script
RustFS bootstrap script/policy
health checks
backup/restore runbook
```

No production credential values are stored in these artifacts.

---

## 18. Acceptance criteria

```text
I01 DEV starts PostgreSQL + RustFS from one documented Compose command
I02 TEST uses isolated DB/object volumes and credentials
I03 PROD manifests use explicit pinned image versions; no `latest`
I04 Backend PostgreSQL runtime user is not a superuser/schema owner
I05 Liquibase uses a distinct migration privilege boundary
I06 RustFS root credential is not used by Backend runtime
I07 Backend RustFS identity is bucket/prefix scoped
I08 no real secrets exist in tracked env/compose files
I09 PROD PostgreSQL/RustFS ports are not public by default
I10 persistent PROD paths survive container recreation
I11 health checks report PostgreSQL and RustFS readiness
I12 DEV/TEST reset cannot address PROD volumes by default
I13 backup artifacts are outside active volumes
I14 clean restore drill reconstructs PostgreSQL + RustFS successfully
I15 restored publication/asset references pass integrity checks
I16 RustFS bind-mount permissions are valid for the container runtime UID
I17 infrastructure works with the normal Backend storage adapter; no direct Flutter/Worker storage credential path appears
```

This infrastructure baseline belongs to B1 and does not add another MVP delivery stage.
