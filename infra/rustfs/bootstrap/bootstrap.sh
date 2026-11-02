#!/bin/sh
set -eu

read_secret() {
  path="$1"
  if [ ! -r "$path" ]; then
    echo "Required secret is missing or unreadable: $path" >&2
    exit 1
  fi
  tr -d '\r\n' < "$path"
}

: "${RUSTFS_ENDPOINT:=http://rustfs:9000}"
: "${RUSTFS_REGION:=us-east-1}"
: "${RUSTFS_BUCKET:=voxprep-assets}"
: "${RUSTFS_POLICY_NAME:=voxprep-backend-rw}"

case "$RUSTFS_BUCKET" in
  *[!a-z0-9.-]*|'')
    echo "Unsafe RustFS bucket name" >&2
    exit 1
    ;;
esac

case "$RUSTFS_POLICY_NAME" in
  *[!A-Za-z0-9._-]*|'')
    echo "Unsafe RustFS policy name" >&2
    exit 1
    ;;
esac

ROOT_ACCESS_KEY="$(read_secret /run/secrets/rustfs_root_access_key)"
ROOT_SECRET_KEY="$(read_secret /run/secrets/rustfs_root_secret_key)"
BACKEND_ACCESS_KEY="$(read_secret /run/secrets/rustfs_backend_access_key)"
BACKEND_SECRET_KEY="$(read_secret /run/secrets/rustfs_backend_secret_key)"

if [ -z "$ROOT_ACCESS_KEY" ] || [ -z "$ROOT_SECRET_KEY" ] || \
   [ -z "$BACKEND_ACCESS_KEY" ] || [ -z "$BACKEND_SECRET_KEY" ]; then
  echo "RustFS credentials must not be empty" >&2
  exit 1
fi

rc alias set voxprep "$RUSTFS_ENDPOINT" "$ROOT_ACCESS_KEY" "$ROOT_SECRET_KEY" \
  --region "$RUSTFS_REGION" --bucket-lookup path >/dev/null

rc ready voxprep
rc bucket create "voxprep/$RUSTFS_BUCKET" --ignore-existing

POLICY_FILE="/tmp/${RUSTFS_POLICY_NAME}.json"
sed "s/__BUCKET__/${RUSTFS_BUCKET}/g" /bootstrap/backend-rw.json > "$POLICY_FILE"

if ! rc admin policy info voxprep "$RUSTFS_POLICY_NAME" >/dev/null 2>&1; then
  rc admin policy create voxprep "$RUSTFS_POLICY_NAME" "$POLICY_FILE"
fi

if ! rc admin user info voxprep "$BACKEND_ACCESS_KEY" >/dev/null 2>&1; then
  rc admin user add voxprep "$BACKEND_ACCESS_KEY" "$BACKEND_SECRET_KEY"
fi

rc admin policy attach voxprep "$RUSTFS_POLICY_NAME" --user "$BACKEND_ACCESS_KEY"

echo "RustFS bootstrap completed."
echo "Bucket and Backend IAM policy are ready."
