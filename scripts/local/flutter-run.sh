#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
cd "$LOCAL_ROOT/mobile/careerspeak_app"
exec flutter run -d macos -t lib/main.dart \
  --dart-define=VOXPREP_ENV=development \
  --dart-define="VOXPREP_API_URL=http://127.0.0.1:${VOXPREP_LOCAL_BACKEND_PORT:-18081}" \
  --dart-define=VOXPREP_MOCK_BILLING=false \
  --dart-define=VOXPREP_MOCK_PURCHASE_VERIFICATION=false "$@"
