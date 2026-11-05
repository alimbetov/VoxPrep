#!/usr/bin/env bash
set -euo pipefail
port="${VOXPREP_LOCAL_BACKEND_PORT:-18081}"
python3 - "$port" <<'PY'
import json, sys, urllib.request
for kind in ('liveness', 'readiness'):
    url = f'http://127.0.0.1:{int(sys.argv[1])}/actuator/health/{kind}'
    with urllib.request.urlopen(url, timeout=10) as response:
        result = json.load(response)
        if result.get('status') != 'UP':
            sys.exit(f'FAIL: {url}: {result}')
        print(f'PASS: {url} HTTP {response.status} status=UP')
PY
