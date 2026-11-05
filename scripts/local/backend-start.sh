#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
source "$LOCAL_ROOT/scripts/local/java-env.sh"
export SERVER_PORT="${VOXPREP_LOCAL_BACKEND_PORT:-18081}"
if lsof -nP -iTCP:"$SERVER_PORT" -sTCP:LISTEN >/dev/null; then
  echo "BLOCKED: backend port $SERVER_PORT occupied" >&2
  exit 1
fi
cd "$LOCAL_ROOT/backend"
exec mvn -B -ntp spring-boot:run -Dspring-boot.run.profiles=dev
