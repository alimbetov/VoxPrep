#!/usr/bin/env bash
set -euo pipefail
LOCAL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export COMPOSE_PROJECT_NAME=voxprep-local
export POSTGRES_HOST_PORT=55432
export RUSTFS_API_HOST_PORT=19000
export RUSTFS_CONSOLE_HOST_PORT=19001
export POSTGRES_VOLUME_NAME=voxprep_local_pgdata
export RUSTFS_DATA_VOLUME_NAME=voxprep_local_rustfs_data
export RUSTFS_LOG_VOLUME_NAME=voxprep_local_rustfs_logs
export BACKEND_NETWORK_NAME=voxprep-local-private
export SERVER_PORT="${SERVER_PORT:-18080}"
export VOXPREP_DB_URL=jdbc:postgresql://127.0.0.1:55432/voxprep_dev
export VOXPREP_STORAGE_ENDPOINT=http://127.0.0.1:19000
export VOXPREP_SECRET_DIR="$LOCAL_ROOT/infra/secrets/dev/backend/"
export SPRING_PROFILES_ACTIVE=dev

compose() {
  docker compose --env-file "$LOCAL_ROOT/infra/env/dev.env.example" \
    -f "$LOCAL_ROOT/infra/compose/compose.dev.yml" "$@"
}

# Apply a wall-clock timeout even where macOS has no GNU timeout utility.
bounded() {
  python3 - "$@" <<'PY'
import subprocess, sys
try:
    result = subprocess.run(sys.argv[2:], timeout=int(sys.argv[1]))
    sys.exit(result.returncode)
except subprocess.TimeoutExpired:
    print('Command timed out', file=sys.stderr)
    sys.exit(124)
PY
}

preflight() {
  python3 - "$LOCAL_ROOT" <<'PY'
import shutil, socket, sys
free = shutil.disk_usage(sys.argv[1]).free / 1024**3
if free < 20:
    sys.exit(f'BLOCKED: {free:.1f} GiB free; at least 20 GiB required before local startup. No cleanup performed.')
PY
  bounded 15 docker info --format '{{.OSType}}/{{.Architecture}}'
  # Check only ports for new containers: an existing container must pass Compose's
  # own reconciliation/health checks instead of being mistaken for a collision.
  local service port ids
  local -a ports
  for service in postgres rustfs; do
    ids="$(compose ps -aq "$service")"
    if [[ -z "$ids" ]]; then
      if [[ "$service" == postgres ]]; then
        ports=("$POSTGRES_HOST_PORT")
      else
        ports=("$RUSTFS_API_HOST_PORT" "$RUSTFS_CONSOLE_HOST_PORT")
      fi
      for port in "${ports[@]}"; do
        if lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null; then
          echo "BLOCKED: TCP port $port is already in use" >&2
          return 1
        fi
      done
    fi
  done
}
