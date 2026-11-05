# Local macOS dependencies

See `ENVIRONMENT_AUDIT.md` for actual versions and evidence. No dependencies were
installed by A0.

| Component | Required by source | Local state |
|---|---|---|
| Java | 21 | READY installed; select explicitly, default is 17 |
| Maven | existing backend Maven build | 3.8.7 available; build NOT RUN |
| Docker/Compose | DEV PostgreSQL + RustFS, worker | READY daemon; image qualification NOT RUN |
| PostgreSQL | 18.6-bookworm | NOT RUN; unrelated local PostgreSQL 15 is unsuitable |
| RustFS / CLI | 1.0.4 / v0.1.30 | NOT RUN; existing latest container is unsuitable |
| Worker | Python 3.12.16, Piper 1.4.2, FFmpeg 5.1.9 per Dockerfile | NOT RUN; pinned downloads/build required |
| Flutter | CI 3.47.9; project Dart >=3.12 <4 | Installed 3.47.7 / Dart 3.13.5; qualification pending |
| Drift | 2.35.3 / drift_flutter 0.3.1 | Dependencies declared; runtime NOT RUN |
| Apple tools | Xcode + CocoaPods + selected runner | Tools READY; runner MISSING |
| Disk | enough for OCI layers, Maven, pub and Xcode outputs | BLOCKED: only 4.7 GiB available; required total not yet measured |

## Commands for the next tasks

Re-record host evidence after changes:

```bash
./scripts/local/audit.sh
```

Use the installed JDK without changing system defaults:

```bash
export JAVA_HOME="$HOME/.sdkman/candidates/java/21.0.1-tem"
export PATH="$JAVA_HOME/bin:$PATH"
java -version
mvn -version
```

After disk capacity is resolved, A1 should check unused ports with `lsof`, then
pass explicit `POSTGRES_HOST_PORT`, `RUSTFS_API_HOST_PORT` and
`RUSTFS_CONSOLE_HOST_PORT` overrides to the existing DEV Compose. Its example env
file supplies defaults; shell exports take precedence. A2 must use the same DB/S3
ports via `VOXPREP_DB_URL` and `VOXPREP_STORAGE_ENDPOINT`, plus a free `SERVER_PORT`.
Do not run the README default startup against the currently occupied ports.

Flutter candidate configuration is `--dart-define=VOXPREP_ENV=development`
and `--dart-define=VOXPREP_API_URL=http://127.0.0.1:<selected-backend-port>`.
This is not yet a runnable GUI command: platform generation, entitlements,
HTTP permissions and plugin support must be verified by A4 first.
