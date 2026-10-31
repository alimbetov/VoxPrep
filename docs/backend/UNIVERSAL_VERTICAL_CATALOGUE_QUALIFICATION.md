# Universal Vertical Catalogue — Qualification Policy

This document freezes the acceptance policy for `feat/universal-vertical-catalogue`.

## Evidence layers

The branch is accepted only when all independent evidence layers are green on the same exact SHA:

- **G1** — seven committed learner UI golden baselines.
- **G2** — golden visual regression comparison.
- **C1** — exhaustive matrices for small finite contract spaces.
- **C2** — cross-layer combination qualification for cache/network/resolution behavior.
- **C3** — positive end-to-end and domain scenarios.
- **C4** — negative fail-closed scenarios.
- **C5** — adversarial corruption, ownership, restart and concurrency scenarios.
- **T1** — real LCOV measurement.
- **T2** — generated low-coverage ledger.
- **T3** — critical-domain tests.
- **T4** — repository/storage tests.
- **T5** — controller/state tests.
- **T6** — learner UI state tests.
- **T7** — at least 90% line coverage of handwritten production Dart.

## Coverage denominator

Coverage is measured from `mobile/careerspeak_app/lib/**` and excludes only generated implementation artifacts:

- `*.g.dart`
- `*.freezed.dart`
- `/generated/`

Production repositories, controllers, services, domain validators and UI code are not excluded merely to raise the percentage.

The coverage job publishes both `coverage/lcov.info` and `coverage/coverage-ledger.md` as CI evidence.

## Ledger-driven remediation order

Coverage work is prioritized by **absolute uncovered production lines**, not by the lowest percentage alone. A large 70% covered controller generally has higher remediation value than a tiny 0% utility.

The remediation order is:

1. critical domain / contract invariants;
2. repositories and storage boundaries;
3. controllers, state machines and concurrency behavior;
4. learner-facing UI states;
5. remaining low-risk glue code.

Tests must exercise meaningful positive, negative or adversarial behavior. Tests whose only purpose is to execute lines without asserting a contract are not accepted as coverage remediation.

## Final qualification

- **Q1 — quality green:** format, generated-code reproducibility, analyze and full Flutter regression.
- **Q2 — coverage-90 green:** aggregate handwritten production coverage is at least 90%.
- **Q3 — verification green:** goldens, combinatorial qualification, domain/repository/controller/UI gates, E2E, offline/restart, corruption, retention and migration tests all pass.
- **Q4 — exact SHA qualification:** Q1, Q2 and Q3 must refer to the same repository commit SHA.

A branch is not declared merge-ready while any of Q1–Q4 remains unproven.
