#!/usr/bin/env bash
# Read-only host inventory; each probe records its own exit code, including failures.
set -euo pipefail
cd "$(dirname "$0")/../.."
exec python3 scripts/local/audit.py
