# VoxPrep B1 Infrastructure

This directory implements the first B1 infrastructure slice for PostgreSQL and RustFS.

## Baseline

```text
PostgreSQL 18.6
RustFS 1.0.4
RustFS CLI rc 0.1.30
```

DEV, TEST and PROD have separate Compose projects, networks, volumes/data roots and secrets.

## DEV quick start

### Windows PowerShell

```powershell
.\infra\scripts\init-secrets.ps1 -Environment dev

docker compose `
  --env-file infra/env/dev.env.example `
  -f infra/compose/compose.dev.yml `
  config

docker compose `
  --env-file infra/env/dev.env.example `
  -f infra/compose/compose.dev.yml `
  up -d

docker compose `
  --env-file infra/env/dev.env.example `
  -f infra/compose/compose.dev.yml `
  ps -a
```

### Linux/macOS

```bash
./infra/scripts/init-secrets.sh dev

docker compose \
  --env-file infra/env/dev.env.example \
  -f infra/compose/compose.dev.yml \
  config

docker compose \
  --env-file infra/env/dev.env.example \
  -f infra/compose/compose.dev.yml \
  up -d

docker compose \
  --env-file infra/env/dev.env.example \
  -f infra/compose/compose.dev.yml \
  ps -a
```

Expected DEV endpoints:

```text
PostgreSQL      127.0.0.1:5432
RustFS S3       127.0.0.1:9000
RustFS Console  127.0.0.1:9001
```

The one-shot `rustfs-bootstrap` service should exit with code `0` after creating the private bucket, Backend IAM user and policy.

Check logs if it does not:

```bash
docker compose --env-file infra/env/dev.env.example -f infra/compose/compose.dev.yml logs postgres rustfs rustfs-bootstrap
```

## PostgreSQL identities

```text
voxprep_bootstrap  container/bootstrap superuser only
voxprep_owner      NOLOGIN ownership/group role
voxprep_migrator   Liquibase/migration role
voxprep_backend    normal Backend runtime role
```

Schema:

```text
app
```

The Backend must use `voxprep_backend` for normal request processing. Liquibase uses `voxprep_migrator`.

Passwords are read from `infra/secrets/<environment>/...` for DEV/TEST and from the external production secret directory for PROD.

## RustFS identities

```text
root credential         bootstrap/break-glass only
Backend IAM credential  normal object access
```

The Backend IAM user receives only the versioned `voxprep-backend-rw` policy for the configured bucket. Flutter and the TTS Worker do not receive RustFS credentials.

Default bucket:

```text
voxprep-assets
```

Application prefixes are logical conventions inside the bucket:

```text
content/
cover/
audio/
tts-model/
staging/
```

## TEST

Generate isolated test secrets and start the stack:

```bash
./infra/scripts/init-secrets.sh test

docker compose \
  --env-file infra/env/test.env.example \
  -f infra/compose/compose.test.yml \
  up -d
```

TEST publishes no PostgreSQL/RustFS host ports by default.

A destructive reset is permitted only for DEV/TEST:

```bash
docker compose --env-file infra/env/test.env.example -f infra/compose/compose.test.yml down -v
```

Never run `down -v` against PROD.

## PROD host preparation

Default host paths:

```text
/srv/voxprep/prod/postgres/data
/srv/voxprep/prod/postgres/backup
/srv/voxprep/prod/rustfs/data
/srv/voxprep/prod/rustfs/logs
/srv/voxprep/prod/rustfs/backup
/etc/voxprep/secrets/prod
```

Example Linux preparation:

```bash
sudo install -d -m 0750 /srv/voxprep/prod/postgres/data
sudo install -d -m 0750 /srv/voxprep/prod/postgres/backup
sudo install -d -m 0750 -o 10001 -g 10001 /srv/voxprep/prod/rustfs/data
sudo install -d -m 0750 -o 10001 -g 10001 /srv/voxprep/prod/rustfs/logs
sudo install -d -m 0750 /srv/voxprep/prod/rustfs/backup
sudo install -d -m 0700 /etc/voxprep/secrets/prod
```

Populate all required production secret files manually or through the deployment secret manager. Do not use the DEV/TEST generator for production credentials.

For the current plain Docker Compose deployment, keep the parent secret directory `0700` and the individual file-backed secret files `0444`. Compose bind-mounts the files directly, and PostgreSQL/RustFS run as non-root users that must be able to read those mounts. The protected parent directory prevents normal host users from traversing to the files. Native orchestrator secrets can use tighter per-secret ownership/mode controls later.

Validate before startup:

```bash
docker compose \
  --env-file infra/env/prod.env.example \
  -f infra/compose/compose.prod.yml \
  config
```

Start:

```bash
docker compose \
  --env-file infra/env/prod.env.example \
  -f infra/compose/compose.prod.yml \
  up -d
```

PROD does not publish PostgreSQL or RustFS ports to the host. They are reachable only on the internal Compose network. The future Backend service must join the same private network.

## Backend wiring target

When the Spring Boot backend module is added, wire it to:

```text
JDBC host: postgres
JDBC port: 5432
JDBC database: environment POSTGRES_DB
runtime user: voxprep_backend
Liquibase user: voxprep_migrator

RustFS endpoint: http://rustfs:9000
RustFS bucket: voxprep-assets
RustFS access key/secret: backend IAM secret files
```

Spring Boot should consume mounted files using config-tree or an equivalent explicit secret-file boundary instead of committing passwords into `application*.yml`.

## Current slice boundary

Implemented now:

```text
INFRA-1 compose DEV/TEST/PROD
INFRA-2 PostgreSQL bootstrap roles/schema
INFRA-3 RustFS bucket/IAM policy bootstrap
local DEV/TEST secret generation
health checks
CI runtime qualification
```

Still pending:

```text
INFRA-4 Spring Boot config-tree wiring
INFRA-6 backup scripts/runbook
INFRA-7 clean backup -> destroy -> restore -> integrity acceptance
PROD image digest pinning after deployment image resolution
```
