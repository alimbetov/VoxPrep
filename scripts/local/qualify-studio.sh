#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
exec python3 "$LOCAL_ROOT/scripts/local/qualify_studio.py"
