# CareerSpeak — Cancelled MVP Scope

**Status:** Normative cancellation record for CareerSpeak v1

The following previously considered directions are not part of the MVP roadmap and must not be implemented unless a later versioned requirement explicitly reintroduces them:

```text
AI recommendation engine
recommendation microservice
AI personalization
LearningActivity backend aggregate
workflow / rules engine
server learner profile
mandatory learner accounts
email/password authentication
Google/Apple learner login
microservice decomposition
API Gateway
Kafka / RabbitMQ for learner-domain flows
Redis as an architectural dependency
Keycloak
advanced SRS / FSRS / SM-2 integration
ML review scheduler
runtime STT
pronunciation scoring
learner audio upload
runtime mobile TTS generation
Hero transition system
complex animation choreography
Rive / Lottie dependency
analytics domain / warehouse before telemetry approval
achievement / badge economy
leaderboards
social graph
remote UI schema
generic EAV content model
```

## Enforcement rule

A new pull request may not add one of these capabilities under a different name or through a generic abstraction unless the product requirements are first versioned and this cancellation record is amended.

## What remains allowed

The MVP may still include:

```text
deterministic local ReviewSchedulingPolicy
installation-scoped authentication
Spring Boot modular monolith
PostgreSQL
RustFS
separate Piper/FFmpeg TTS worker
small native Flutter motion/accessibility fixes
minimal operational telemetry required for production diagnostics
```
