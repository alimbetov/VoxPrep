#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"
case "$ENVIRONMENT" in
  dev|test) ;;
  *)
    echo "Usage: $0 [dev|test]" >&2
    exit 2
    ;;
esac

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="$ROOT_DIR/secrets/$ENVIRONMENT"

umask 077
mkdir -p "$TARGET_DIR"
chmod 700 "$TARGET_DIR"

random_hex() {
  openssl rand -hex "$1"
}

random_access_key() {
  random_hex 16 | tr '[:lower:]' '[:upper:]'
}

write_if_missing() {
  local path="$1"
  local value="$2"
  if [[ -e "$path" ]]; then
    chmod 444 "$path"
    echo "keep  $path"
  else
    printf '%s\n' "$value" > "$path"
    chmod 444 "$path"
    echo "create $path"
  fi
}

write_if_missing "$TARGET_DIR/postgres_bootstrap_password" "$(random_hex 32)"
write_if_missing "$TARGET_DIR/postgres_migrator_password" "$(random_hex 32)"
write_if_missing "$TARGET_DIR/postgres_backend_password" "$(random_hex 32)"
write_if_missing "$TARGET_DIR/rustfs_root_access_key" "$(random_access_key)"
write_if_missing "$TARGET_DIR/rustfs_root_secret_key" "$(random_hex 32)"
write_if_missing "$TARGET_DIR/rustfs_backend_access_key" "$(random_access_key)"
write_if_missing "$TARGET_DIR/rustfs_backend_secret_key" "$(random_hex 32)"

echo "Local $ENVIRONMENT secrets are ready under $TARGET_DIR"
echo "Directory mode is 0700; file mode is 0444 for plain Compose bind-mounted secrets."
