#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
# Deliberately no arbitrary Compose arguments or secret-bearing config output.
compose logs --no-color --tail=100 postgres rustfs
