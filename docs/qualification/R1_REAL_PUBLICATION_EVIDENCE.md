# R1 live publication evidence protocol

Target: [Issue #51](https://github.com/alimbetov/VoxPrep/issues/51) and
[PR #53](https://github.com/alimbetov/VoxPrep/pull/53).

## Evidence source

The `A1 Real Flutter Backend Acceptance` GitHub workflow runs against an isolated
PostgreSQL container, live Spring Boot HTTP server, Content Studio MVC,
RustFS and production Flutter HTTP/Drift adapters. The A1 fixture is created
through authenticated MVC form requests, passes the actual approval lifecycle,
publishes real N and N+1 and closes/reopens a real SQLite file.

After CI succeeds, download the **r1-real-publication-evidence-`SHA`** artifact
from that workflow run. This archive is generated only after successful A1
execution. It contains:

| File | Source | Evidence |
| --- | --- | --- |
| `postgres-publication-snapshot.txt` | Read-only SQL through live test PostgreSQL | singleton CURRENT release, N/N+1 release/root SHA, exact immutable revision/checksums, wire metadata |
| `http-root-n2.json` | Live learner HTTP via production Flutter gateway | N+1 root checksum/version and pack revision identifiers |
| `flutter-drift-evidence.json` | Production Flutter test after SQLite file close/reopen | same CURRENT version, exact free phrase typed body and collection memberships |
| `r1-verified.json` | Fail-closed Python verifier | correlated PostgreSQL root hash, HTTP root hash and reopened Drift CURRENT, duplicate and corruption invariants |
| `01-content-draft.png` | Actual Chromium browser and authenticated Content Studio MVC | Draft form |
| `02-content-approved.png` | Actual Chromium browser and authenticated Content Studio MVC | Approved form |
| `03-publication-current.png` | Actual Chromium browser and authenticated publication MVC | Current release view |

The screenshot script **does not** capture the login page. The archive excludes
passwords, authorization headers, local installation tokens, raw HTTP payloads
and database credentials. DB snapshots include only synthetic A1 test data and
immutable metadata, not raw content bodies.

## Qualification (do not infer from a previous SHA)

1. Record exact PR head SHA and exact GitHub Actions job IDs.
2. Verify all required CI checks are `completed/success` on that exact SHA.
3. Open the A1 artifact and require all seven files above.
4. Inspect `r1-verified.json`: `verification=PASS`, root SHA and version
   match `http-root-n2.json`, published SQL release and `flutter-drift-evidence.json`.
5. Visually inspect the three PNG screenshots for the actual DRAFT, APPROVED and
   CURRENT workflow, missing UI fields, errors and unexpected redirects.
6. Review the screenshots manually and record the reviewer/date in #51.
   Automated screenshot creation is *not* a human visual sign-off.
7. For the merge SHA, verify its own applicable `main` CI checks.
8. Only then mark every verified #51 acceptance item and close R1.

`infra/acceptance/r1-publication-evidence.sql` is a read-only PostgreSQL
snapshot query, and `infra/acceptance/r1-verify-evidence.py` validates the
snapshot against HTTP and Drift. The workflow fails closed on missing screenshots
or mismatched versions/hashes. The fixture is not a production account and does
not prove Google Play/App Store billing, covered independently by R2.
