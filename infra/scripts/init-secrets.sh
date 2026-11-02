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
BACKEND_DIR="$TARGET_DIR/backend"

umask 077
mkdir -p "$TARGET_DIR" "$BACKEND_DIR"
chmod 700 "$TARGET_DIR" "$BACKEND_DIR"

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

project_backend_secret() {
  local name="$1"
  local source="$TARGET_DIR/$name"
  local destination="$BACKEND_DIR/$name"

  rm -f "$destination"
  cp "$source" "$destination"
  chmod 444 "$destination"
}

write_if_missing "$TARGET_DIR/postgres_bootstrap_password" "$(random_hex 32)"
write_if_missing "$TARGET_DIR/postgres_migrator_password" "$(random_hex 32)"
write_if_missing "$TARGET_DIR/postgres_backend_password" "$(random_hex 32)"
write_if_missing "$TARGET_DIR/rustfs_root_access_key" "$(random_access_key)"
write_if_missing "$TARGET_DIR/rustfs_root_secret_key" "$(random_hex 32)"
write_if_missing "$TARGET_DIR/rustfs_backend_access_key" "$(random_access_key)"
write_if_missing "$TARGET_DIR/rustfs_backend_secret_key" "$(random_hex 32)"
write_if_missing "$TARGET_DIR/worker_api_key" "$(random_hex 32)"

project_backend_secret postgres_migrator_password
project_backend_secret postgres_backend_password
project_backend_secret rustfs_backend_access_key
project_backend_secret rustfs_backend_secret_key
project_backend_secret worker_api_key

echo "Local $ENVIRONMENT infrastructure secrets are ready under $TARGET_DIR"
echo "Backend-only secret projection is ready under $BACKEND_DIR"
echo "Directory mode is 0700; file mode is 0444 for plain Compose bind-mounted secrets."
