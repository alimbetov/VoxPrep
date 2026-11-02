# VoxPrep / CareerSpeak Backend v1 — Design Index

**Status:** entry point for Backend design and implementation.

Use documents in this order:

1. [`BACKEND_API_CONTRACT_BASELINE.md`](BACKEND_API_CONTRACT_BASELINE.md) — authoritative Flutter/learner HTTP and DTO baseline; aggregate OpenAPI is `../../contracts/learner-api-v2.yaml`.
2. [`BACKEND_V1_SYSTEM_DESIGN_SPEC.md`](BACKEND_V1_SYSTEM_DESIGN_SPEC.md) — internal Spring Boot architecture, security zones, authoring/moderation, TTS provisioning and acceptance principles.
3. [`BACKEND_V1_DOMAIN_COMPOSITION.md`](BACKEND_V1_DOMAIN_COMPOSITION.md) — bounded contexts, aggregates, ownership, candidate logical tables and cross-context references.
4. [`BACKEND_V1_DATABASE_AND_ENVIRONMENT_PROFILES.md`](BACKEND_V1_DATABASE_AND_ENVIRONMENT_PROFILES.md) — `dev=H2`, `test/prod=PostgreSQL`, Liquibase and Testcontainers policy.
5. [`BACKEND_V1_IMPLEMENTATION_ROADMAP.md`](BACKEND_V1_IMPLEMENTATION_ROADMAP.md) — B0–B9 implementation order and exact-SHA acceptance gates.
6. [`CAREERSPEAK_BACKEND_TTS_REQUIREMENTS.md`](CAREERSPEAK_BACKEND_TTS_REQUIREMENTS.md) plus Worker integration/auth documents — normative Worker protocol/lifecycle.
7. [`../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`](../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md) — cross-system ownership and immutable publication invariants.
8. [`../mobile/FLUTTER_ENVIRONMENTS.md`](../mobile/FLUTTER_ENVIRONMENTS.md) — Flutter environment/runtime policy that Backend deployment must support.

## Core design decision

```text
ADMIN Spring MVC
      -> mutable authoring/moderation
      -> immutable approved revisions
      -> Publication candidate
      -> immutable learner publication
      -> Flutter

ContentRevision + TtsVoiceModel
      -> TtsJob
      -> Worker
      -> FileAsset
      -> review/bind
      -> later Publication
```

## Database decision

```text
dev  -> H2 for fast local development only
test -> PostgreSQL, preferably Testcontainers in CI
prod -> PostgreSQL
```

H2 is never accepted as PostgreSQL compatibility, TTS concurrency, migration or release qualification evidence.

## External-model decision

Spring Boot may provision missing configured Piper models during Backend initialization through a model-provisioning use-case. The Worker never downloads directly from Hugging Face and never receives registry/RustFS credentials.

Production ACTIVE models require immutable source provenance, Backend-computed SHA-256 and license/commercial-use qualification.
