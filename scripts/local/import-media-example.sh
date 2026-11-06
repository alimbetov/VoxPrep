#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
cd "$LOCAL_ROOT"
exec python3 scripts/local/import-media-example.py
