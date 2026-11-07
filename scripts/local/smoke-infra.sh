#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
compose exec -T postgres pg_isready -U voxprep_bootstrap -d voxprep_dev
compose exec -T postgres sh -eu <<'SH'
  export PGPASSWORD="$(cat /run/secrets/postgres_backend_password)"
  psql -h 127.0.0.1 -U voxprep_backend -d voxprep_dev -v ON_ERROR_STOP=1 <<'SQL'
SELECT 1 / CASE WHEN current_user = 'voxprep_backend' THEN 1 ELSE 0 END AS runtime_authenticated;
SELECT 1 / CASE WHEN has_schema_privilege(current_user, 'app', 'USAGE')
 AND NOT has_schema_privilege(current_user, 'app', 'CREATE')
 AND NOT has_schema_privilege(current_user, 'liquibase', 'USAGE')
 THEN 1 ELSE 0 END AS runtime_boundary;
SQL
SH
compose exec -T rustfs curl -fsS http://localhost:9000/health/ready
echo 'PASS: PostgreSQL readiness, authenticated runtime SQL/schema privileges, RustFS readiness.'
echo 'NOT RUN: S3 roundtrip, persistence restart, Liquibase table denial (requires A2 migrations).'
