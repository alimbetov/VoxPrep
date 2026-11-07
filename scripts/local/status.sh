#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
compose ps -a
echo 'Scope: infrastructure only; backend/worker/Flutter acceptance NOT RUN.'
