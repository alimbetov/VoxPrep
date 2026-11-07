#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
cd "$LOCAL_ROOT/mobile/careerspeak_app"
exec flutter run -d macos -t lib/main_demo.dart "$@"
