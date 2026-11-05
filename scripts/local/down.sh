#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
if [[ $# -ne 0 ]]; then
  echo 'Usage: down.sh (volumes and secrets are always preserved)' >&2
  exit 2
fi
compose down --timeout 30
