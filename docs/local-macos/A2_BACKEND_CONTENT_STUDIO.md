# A2 — Real Spring Boot + Content Studio

## Codex task

Use real source in `backend/` (Java 21 / Spring Boot 4.1.2), `application.yml` and `application-dev.yml` and existing secret config tree `infra/secrets/dev/backend/`. Do not invent endpoints.

1. Start on host with documented `mvn -B -ntp spring-boot:run -Dspring-boot.run.profiles=dev`, after INFRA READY.
2. Confirm Liquibase migration identity `voxprep_migrator`, runtime identity `voxprep_backend`, and app/liquibase permissions. No H2 or in-memory substitutes.
3. Confirm backend S3 client uses backend IAM, not root.
4. Confirm `/actuator/health/liveness` and `/actuator/health/readiness` independently; readiness must degrade on real external dependency loss, liveness remains process-focused.
5. Locate actual Content Studio MVC authentication/routes and verify via authorized session: create → edit → attach image (where supported) → validate → approve → publish.
6. Locate XML template download, import and validator. Negative XML cases must be rejected without partially publishing data.
7. Verify PostgreSQL revision and CURRENT, HTTP manifest/payload hashes, backend storage objects and version consistency. Generate a DEV fixture through application APIs/domain flows, not direct SQL writes bypassing publication.
8. Write `scripts/local/backend-start.sh`, `smoke-backend.sh`, and document real URLs/commands.
9. If functionality is incomplete, report BLOCKED accurately rather than replacing production path with mock.

## Smoke IDs

API-01 actual Spring Boot readiness; API-02 authorized MVC access; API-03 XML validation and reject; API-04 draft→approval→publication; API-05 CURRENT/manifest/payload from HTTP; API-06 SQL vs HTTP vs payload SHA-256/revision match.

## Done

Real HTTP, SQL and S3 evidence match. Test on exact SHA; no guessed endpoint paths or fake approval bypass.
