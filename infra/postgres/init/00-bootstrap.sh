#!/usr/bin/env bash
set -euo pipefail

read_secret() {
  local path="$1"
  if [[ ! -r "$path" ]]; then
    echo "Required secret is missing or unreadable: $path" >&2
    exit 1
  fi
  tr -d '\r\n' < "$path"
}

MIGRATOR_PASSWORD="$(read_secret /run/secrets/postgres_migrator_password)"
BACKEND_PASSWORD="$(read_secret /run/secrets/postgres_backend_password)"

if [[ -z "$MIGRATOR_PASSWORD" || -z "$BACKEND_PASSWORD" ]]; then
  echo "PostgreSQL role passwords must not be empty" >&2
  exit 1
fi

psql \
  --set=ON_ERROR_STOP=1 \
  --username "$POSTGRES_USER" \
  --dbname "$POSTGRES_DB" \
  --set=db_name="$POSTGRES_DB" \
  --set=migrator_password="$MIGRATOR_PASSWORD" \
  --set=backend_password="$BACKEND_PASSWORD" <<'EOSQL'

SELECT 'CREATE ROLE voxprep_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'voxprep_owner')
\gexec

SELECT 'CREATE ROLE voxprep_migrator LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'voxprep_migrator')
\gexec

SELECT 'CREATE ROLE voxprep_backend LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'voxprep_backend')
\gexec

ALTER ROLE voxprep_migrator PASSWORD :'migrator_password';
ALTER ROLE voxprep_backend PASSWORD :'backend_password';

GRANT voxprep_owner TO voxprep_migrator;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;

CREATE SCHEMA IF NOT EXISTS app AUTHORIZATION voxprep_owner;

GRANT CONNECT ON DATABASE :"db_name" TO voxprep_migrator;
GRANT CONNECT ON DATABASE :"db_name" TO voxprep_backend;

GRANT USAGE, CREATE ON SCHEMA app TO voxprep_migrator;
GRANT USAGE ON SCHEMA app TO voxprep_backend;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app TO voxprep_backend;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA app TO voxprep_backend;

ALTER DEFAULT PRIVILEGES FOR ROLE voxprep_migrator IN SCHEMA app
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO voxprep_backend;
ALTER DEFAULT PRIVILEGES FOR ROLE voxprep_migrator IN SCHEMA app
  GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO voxprep_backend;

ALTER DEFAULT PRIVILEGES FOR ROLE voxprep_owner IN SCHEMA app
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO voxprep_backend;
ALTER DEFAULT PRIVILEGES FOR ROLE voxprep_owner IN SCHEMA app
  GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO voxprep_backend;

ALTER ROLE voxprep_migrator IN DATABASE :"db_name" SET search_path TO app, public;
ALTER ROLE voxprep_backend IN DATABASE :"db_name" SET search_path TO app, public;
EOSQL

echo "PostgreSQL bootstrap completed for database '$POSTGRES_DB'."
echo "Runtime role: voxprep_backend; migration role: voxprep_migrator; owner role: voxprep_owner."
