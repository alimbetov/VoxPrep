#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

COMPOSE=(docker compose --env-file infra/env/test.env.example -f infra/compose/compose.test.yml)
TMP="$ROOT/.tmp/b8-real-tts"
MODEL="$TMP/en_US-lessac-medium.onnx"
CONFIG="$TMP/en_US-lessac-medium.onnx.json"
FINAL_MP3="$TMP/final.mp3"
BACKEND_LOG="$TMP/backend.log"
WORKER_LOG="$TMP/worker.log"
BACKEND_PORT=18081
BACKEND_PID=""
WORKER_ID=""

MODEL_REVISION="a517d785c98755ae1bb6c1bffd48a83e10c2f36f"
MODEL_URL="https://huggingface.co/rhasspy/piper-voices/resolve/${MODEL_REVISION}/en/en_US/lessac/medium/en_US-lessac-medium.onnx"
CONFIG_URL="https://huggingface.co/rhasspy/piper-voices/resolve/${MODEL_REVISION}/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json"
EXPECTED_MODEL_SHA="5efe09e69902187827af646e1a6e9d269dee769f9877d17b16b1b46eeaaf019f"
TTS_TEXT="Tell me about yourself and your experience."
FINGERPRINT="cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
JOB_ID="b8000000-0000-0000-0000-000000000006"
FILE_ID="b8000000-0000-0000-0000-000000000007"

cleanup() {
  set +e
  if [[ -n "$WORKER_ID" ]]; then
    docker stop --time 10 "$WORKER_ID" >/dev/null 2>&1 || true
    docker logs "$WORKER_ID" >"$WORKER_LOG" 2>&1 || true
    docker rm "$WORKER_ID" >/dev/null 2>&1 || true
  fi
  if [[ -n "$BACKEND_PID" ]]; then
    kill "$BACKEND_PID" >/dev/null 2>&1 || true
    wait "$BACKEND_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

rm -rf "$TMP"
mkdir -p "$TMP"

printf '%s\n' 'A01: download pinned real Piper model/config'
curl --fail --location --retry 3 --output "$MODEL" "$MODEL_URL"
curl --fail --location --retry 3 --output "$CONFIG" "$CONFIG_URL"
MODEL_SHA="$(sha256sum "$MODEL" | awk '{print $1}')"
CONFIG_SHA="$(sha256sum "$CONFIG" | awk '{print $1}')"
MODEL_SIZE="$(stat -c %s "$MODEL")"
CONFIG_SIZE="$(stat -c %s "$CONFIG")"
[[ "$MODEL_SHA" == "$EXPECTED_MODEL_SHA" ]]
[[ "$CONFIG_SHA" =~ ^[0-9a-f]{64}$ ]]
[[ "$MODEL_SIZE" -gt 60000000 ]]
[[ "$CONFIG_SIZE" -gt 1000 ]]
printf '%s\n' "A01 PASS model_sha=$MODEL_SHA config_sha=$CONFIG_SHA"

printf '%s\n' 'A02: start qualified PostgreSQL/RustFS and bootstrap private bucket'
./infra/scripts/init-secrets.sh test
"${COMPOSE[@]}" config --quiet
"${COMPOSE[@]}" up -d --wait postgres rustfs
"${COMPOSE[@]}" run --rm rustfs-bootstrap
printf '%s\n' 'A02 PASS'

printf '%s\n' 'A03: upload exact model/config into private RustFS'
"${COMPOSE[@]}" run --rm \
  -v "$TMP:/fixtures:ro" \
  --entrypoint /bin/sh rustfs-bootstrap -c '
    set -eu
    read_secret() { tr -d "\r\n" < "$1"; }
    root_access="$(read_secret /run/secrets/rustfs_root_access_key)"
    root_secret="$(read_secret /run/secrets/rustfs_root_secret_key)"
    rc alias set b8 http://rustfs:9000 "$root_access" "$root_secret" --region us-east-1 --bucket-lookup path >/dev/null
    rc cp /fixtures/en_US-lessac-medium.onnx b8/voxprep-assets/tts/models/b8/en_US-lessac-medium.onnx >/dev/null
    rc cp /fixtures/en_US-lessac-medium.onnx.json b8/voxprep-assets/tts/models/b8/en_US-lessac-medium.onnx.json >/dev/null
    rc stat b8/voxprep-assets/tts/models/b8/en_US-lessac-medium.onnx >/dev/null
    rc stat b8/voxprep-assets/tts/models/b8/en_US-lessac-medium.onnx.json >/dev/null
  '
printf '%s\n' 'A03 PASS'

printf '%s\n' 'A04: build and start real Backend with production changelog'
mvn -B -ntp -f backend/pom.xml -DskipTests package
BACKEND_JAR="$(find backend/target -maxdepth 1 -type f -name 'voxprep-backend-*.jar' ! -name '*.original' | head -n 1)"
[[ -n "$BACKEND_JAR" ]]
export SPRING_CONFIG_IMPORT="configtree:${ROOT}/infra/secrets/test/backend/"
export VOXPREP_DB_URL="jdbc:postgresql://127.0.0.1:55432/voxprep_test"
export VOXPREP_STORAGE_ENDPOINT="http://127.0.0.1:19000"
export SERVER_PORT="$BACKEND_PORT"
java -jar "$BACKEND_JAR" >"$BACKEND_LOG" 2>&1 &
BACKEND_PID=$!
for _ in $(seq 1 60); do
  if curl --fail --silent "http://127.0.0.1:${BACKEND_PORT}/actuator/health/readiness" | grep -q '"status":"UP"'; then
    break
  fi
  if ! kill -0 "$BACKEND_PID" 2>/dev/null; then
    cat "$BACKEND_LOG"
    exit 1
  fi
  sleep 1
done
curl --fail --silent "http://127.0.0.1:${BACKEND_PORT}/actuator/health/readiness" | grep -q '"status":"UP"'
printf '%s\n' 'A04 PASS'

printf '%s\n' 'A05: seed exact voice/model/content/job identities'
TEXT_SHA="$(printf '%s' "$TTS_TEXT" | sha256sum | awk '{print $1}')"
CONTENT_SHA="$TEXT_SHA"
"${COMPOSE[@]}" exec -T postgres psql \
  --set=ON_ERROR_STOP=1 \
  --username voxprep_bootstrap \
  --dbname voxprep_test \
  --set=model_sha="$MODEL_SHA" \
  --set=config_sha="$CONFIG_SHA" \
  --set=model_size="$MODEL_SIZE" \
  --set=config_size="$CONFIG_SIZE" \
  --set=tts_text="$TTS_TEXT" \
  --set=text_sha="$TEXT_SHA" \
  --set=content_sha="$CONTENT_SHA" \
  --set=fingerprint="$FINGERPRINT" \
  < infra/acceptance/b8-real-tts-seed.sql
printf '%s\n' 'A05 PASS'

printf '%s\n' 'A06: reject unauthenticated worker claim'
HTTP_CODE="$(curl --silent --output /dev/null --write-out '%{http_code}' \
  -H 'Content-Type: application/json' \
  -d '{"workerId":"unauthorized"}' \
  "http://127.0.0.1:${BACKEND_PORT}/internal/v1/tts/jobs/claim")"
[[ "$HTTP_CODE" == "401" ]]
printf '%s\n' 'A06 PASS'

printf '%s\n' 'A07-A09: run real Worker container through claim, Backend-only model delivery, Piper, FFmpeg and lease heartbeat'
docker build -t voxprep-tts-worker:b8 ./worker
WORKER_TOKEN="$(tr -d '\r\n' < infra/secrets/test/backend/worker_api_key)"
[[ -n "$WORKER_TOKEN" ]]
WORKER_ID="$(docker run -d --network host \
  -e BASE_URL="http://127.0.0.1:${BACKEND_PORT}" \
  -e WORKER_TOKEN="$WORKER_TOKEN" \
  -e WORKER_ID=b8-real-worker \
  -e POLL_INTERVAL_SECONDS=0.25 \
  -e LEASE_HEARTBEAT_INTERVAL_SECONDS=2 \
  -e HTTP_CONNECT_TIMEOUT_SECONDS=5 \
  -e HTTP_REQUEST_TIMEOUT_SECONDS=60 \
  -e LOG_LEVEL=INFO \
  voxprep-tts-worker:b8)"

READY="false"
for _ in $(seq 1 180); do
  STATUS="$("${COMPOSE[@]}" exec -T postgres psql -At --username voxprep_bootstrap --dbname voxprep_test \
    -c "select status from app.tts_job where id='${JOB_ID}'")"
  if [[ "$STATUS" == "READY" ]]; then
    READY="true"
    break
  fi
  if [[ "$STATUS" == "FAILED" ]]; then
    docker logs "$WORKER_ID" || true
    cat "$BACKEND_LOG"
    exit 1
  fi
  sleep 1
done
[[ "$READY" == "true" ]]
printf '%s\n' 'A07-A09 PASS'

printf '%s\n' 'A10: verify durable DB finalization and exact output identity'
ROW="$("${COMPOSE[@]}" exec -T postgres psql -At --username voxprep_bootstrap --dbname voxprep_test -F '|' -c "
  select j.status, a.status, a.kind, a.media_type, a.sha256, a.size_bytes, a.object_key,
         j.finalized_worker_id, j.finalized_lease_token
    from app.tts_job j
    join app.file_asset a on a.id = j.output_asset_id
   where j.id='${JOB_ID}' and j.file_id='${FILE_ID}';")"
IFS='|' read -r JOB_STATUS ASSET_STATUS ASSET_KIND MEDIA_TYPE OUTPUT_SHA OUTPUT_SIZE OUTPUT_KEY FINAL_WORKER FINAL_LEASE <<<"$ROW"
[[ "$JOB_STATUS" == "READY" ]]
[[ "$ASSET_STATUS" == "READY" ]]
[[ "$ASSET_KIND" == "TTS_AUDIO" ]]
[[ "$MEDIA_TYPE" == "audio/mpeg" ]]
[[ "$OUTPUT_SHA" =~ ^[0-9a-f]{64}$ ]]
[[ "$OUTPUT_SIZE" -gt 1000 ]]
[[ "$FINAL_WORKER" == "b8-real-worker" ]]
[[ -n "$FINAL_LEASE" ]]
printf '%s\n' 'A10 PASS'

printf '%s\n' 'A11: verify RustFS MP3 bytes, audio QC and secret non-leakage'
"${COMPOSE[@]}" run --rm \
  -v "$TMP:/fixtures" \
  --entrypoint /bin/sh rustfs-bootstrap -c "
    set -eu
    read_secret() { tr -d '\\r\\n' < \"\$1\"; }
    root_access=\"\$(read_secret /run/secrets/rustfs_root_access_key)\"
    root_secret=\"\$(read_secret /run/secrets/rustfs_root_secret_key)\"
    rc alias set b8 http://rustfs:9000 \"\$root_access\" \"\$root_secret\" --region us-east-1 --bucket-lookup path >/dev/null
    rc stat \"b8/voxprep-assets/${OUTPUT_KEY}\" >/dev/null
    rc cp \"b8/voxprep-assets/${OUTPUT_KEY}\" /fixtures/final.mp3 >/dev/null
  "
[[ "$(sha256sum "$FINAL_MP3" | awk '{print $1}')" == "$OUTPUT_SHA" ]]
docker run --rm --entrypoint ffprobe -v "$FINAL_MP3:/input/final.mp3:ro" voxprep-tts-worker:b8 \
  -v error -select_streams a:0 -show_entries stream=codec_name,sample_rate,channels -of default=noprint_wrappers=1 /input/final.mp3 \
  | tee "$TMP/ffprobe.txt"
grep -q '^codec_name=mp3$' "$TMP/ffprobe.txt"
grep -q '^sample_rate=24000$' "$TMP/ffprobe.txt"
grep -q '^channels=1$' "$TMP/ffprobe.txt"

docker logs "$WORKER_ID" >"$WORKER_LOG" 2>&1
if grep -Fq "$WORKER_TOKEN" "$WORKER_LOG" || grep -Fq "$WORKER_TOKEN" "$BACKEND_LOG"; then
  echo 'WORKER_TOKEN leaked to logs' >&2
  exit 1
fi
printf '%s\n' 'A11 PASS'
printf '%s\n' 'B8 REAL BACKEND <-> WORKER ACCEPTANCE PASSED'
