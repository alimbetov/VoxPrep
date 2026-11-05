#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
source "$LOCAL_ROOT/scripts/local/java-env.sh"
cd "$LOCAL_ROOT"
exec mvn -B -ntp -f backend/pom.xml -Dtest=LocalMacTtsModelSetupTest \
  -Dvoxprep.local.tts.setup=true test
