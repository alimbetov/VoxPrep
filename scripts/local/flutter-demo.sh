#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
cd "$LOCAL_ROOT/mobile/careerspeak_app"
exec flutter run -d web-server -t lib/demo_web_main.dart \
  --web-hostname=127.0.0.1 --web-port="${VOXPREP_DEMO_PORT:-3000}" \
  --dart-define=VOXPREP_DEMO=true "$@"
