#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
preflight
"$LOCAL_ROOT/infra/scripts/init-secrets.sh" dev
compose config --quiet
compose up -d --wait --wait-timeout 120 postgres rustfs
bounded 180 docker compose --env-file "$LOCAL_ROOT/infra/env/dev.env.example" \
  -f "$LOCAL_ROOT/infra/compose/compose.dev.yml" run --rm rustfs-bootstrap
echo 'Infrastructure started. Backend and worker startup are not implemented yet.'
echo "Backend target: http://127.0.0.1:$SERVER_PORT (check port availability before A2)."
