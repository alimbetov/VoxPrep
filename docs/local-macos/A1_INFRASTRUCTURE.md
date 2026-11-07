# A1 — PostgreSQL 18.6 + RustFS 1.0.4

## Codex task

Reuse `infra/compose/compose.dev.yml`, `infra/env/dev.env.example`, `infra/scripts/init-secrets.sh`, bootstrap scripts, IAM policy and named volumes. Check Docker arm64 compatibility and existing resources before launch.

1. Generate DEV secrets using existing generator only if absent; never print secrets.
2. Run `docker compose ... config`, then `up -d --wait postgres rustfs`, then `run --rm rustfs-bootstrap`. A successful one-shot bootstrap exits 0; it is not a long-running health check.
3. Prove `pg_isready` and authenticated `SELECT 1`, inspect `app` and `liquibase` schemas and role separation.
4. Prove RustFS ready, bucket `voxprep-assets` exists, backend IAM can PUT/GET/DELETE a uniquely prefixed ephemeral object; never use root credentials for normal operations.
5. Verify persistence after nondestructive restart of both containers. Check runtime DB role cannot CREATE TABLE in `app` and cannot read Liquibase metadata (expected denied, with transaction rollback).
6. Implement safe operator wrappers `scripts/local/up.sh`, `down.sh`, `status.sh`, `logs.sh` (coordinate with A2/A3), `smoke-infra.sh`.
7. Require idempotency, proper error codes, explicit timeouts, cleanup of only the ephemeral test object, and redaction; prohibit `down -v`.

## Smoke IDs

INF-01 postgres healthy; INF-02 real SQL `SELECT 1`; INF-03 migration/runtime role isolation; INF-04 RustFS readiness; INF-05 authenticated S3 roundtrip; INF-06 persistent state after restart. See `SMOKE_MATRIX.md`.

## Done

All six checks PASS, with Docker status, SQL evidence, RustFS metadata/checksum and no leaked credentials. Do not treat `docker ps` alone as proof of S3 or SQL operations.
