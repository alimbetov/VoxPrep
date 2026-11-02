# Contracts

## Backend B1 source-of-truth

For new Spring Boot Backend design, start with:

1. `learner-api-v2.yaml` — authoritative aggregate learner HTTP/wire contract.
2. `docs/backend/BACKEND_API_CONTRACT_BASELINE.md` — normative cross-contract interpretation and Backend boundary.
3. Domain component contracts referenced by the aggregate:
   - `c2-content-catalog-v1.yaml` — typed learner content payloads;
   - `c2-content-catalog-v3.yaml` — FREE/FULL collection access semantics;
   - `c2-content-audio-v1.yaml` — learner audio/media metadata;
   - `c3-assessment-v1.yaml` — immutable practice-test/question payloads;
   - `c4-catalogue-publication-v2.yaml` — universal catalogue/publication schema-v2 invariants;
   - `content-cover-v1.yaml` — cover-role semantics;
   - `locale-configuration-v1.yaml` — locale/fallback configuration.

## Compatibility documents

`learner-api-v1.yaml` is retained as an earlier aggregate compatibility snapshot. It is **superseded for Backend B1 design** because the production Flutter client already uses additive catalogue, assessment and purchase-verification endpoints that v1 did not aggregate, and newer component contracts define richer content/catalogue semantics.

The public transport namespace intentionally remains `/api/v1`. The v2 filename/version refers to the consolidated contract document, not a forced HTTP major-version migration.

## Change rule

If production Flutter wire behavior and a versioned public contract disagree:

```text
observe production behavior
-> determine intended semantic contract
-> change the versioned contract deliberately
-> add qualification coverage
```

Do not silently change the client, weaken publication/security invariants, or infer Backend DTOs from JPA entities.
