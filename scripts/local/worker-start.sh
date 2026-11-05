#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
cd "$LOCAL_ROOT"
python3 - "${VOXPREP_LOCAL_BACKEND_PORT:-18081}" <<'PY'
from pathlib import Path
import os, sys
root = Path('infra/secrets/dev')
token = (root / 'backend/worker_api_key').read_text().strip()
if not token or '\n' in token:
    raise SystemExit('Invalid worker token file')
path = root / 'worker.env'
fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
with os.fdopen(fd, 'w') as output:
    output.write('BASE_URL=http://host.docker.internal:' + str(int(sys.argv[1])) + '\n')
    output.write('WORKER_TOKEN=' + token + '\n')
os.chmod(path, 0o600)
PY
if docker container inspect voxprep-local-tts-worker >/dev/null 2>&1; then
  running="$(docker inspect --format '{{.State.Running}}' voxprep-local-tts-worker)"
  if [[ "$running" == true ]]; then
    echo 'Worker already running: voxprep-local-tts-worker'
    exit 0
  fi
  docker start voxprep-local-tts-worker
  exit 0
fi
docker run -d --name voxprep-local-tts-worker \
  --env-file "$LOCAL_ROOT/infra/secrets/dev/worker.env" \
  -e WORKER_ID=voxprep-local-worker-01 \
  -e POLL_INTERVAL_SECONDS=1 \
  -e LEASE_HEARTBEAT_INTERVAL_SECONDS=5 \
  -v voxprep_local_tts_models:/var/lib/voxprep/tts/models \
  voxprep-tts-worker:local
