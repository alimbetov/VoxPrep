# VoxPrep main — technical acceptance gate

This document defines the release qualification gate for a single **exact Git SHA**. It does not claim that all tests already passed.

## Required automated gates on one SHA

1. **B1 Backend Foundation Qualification:** PostgreSQL + RustFS bootstrap, Liquibase and Backend integration tests.
2. **B8 Real Backend Worker Acceptance:** real Piper worker + Backend/RustFS integration and replay/lease checks.
3. **Flutter Main CI:** format, static analysis, Drift schema, widget, audio redownload/offline, and golden snapshot tests.
4. **A1 Real Flutter Backend Acceptance:** real PostgreSQL -> Spring Boot HTTP -> Content Studio review/publication -> Flutter/Drift -> reopen and real-media HTTP checks. The workflow uploads R1 evidence with correlated publication state, browser screenshots and verification JSON.

A result on a different SHA **does not qualify** a new release SHA. Store the exact link to each run in the release record.

## Operator end-to-end check after CI

- Create an editable content revision and complete the review lifecycle in Content Studio.
- Attach a valid cover/content image as applicable and generate/verify the MP3 in real RustFS (Piper path on main).
- Publish an immutable release and confirm the intended material appears in `publication_current`.
- Open the material in an actual Flutter build, verify the published text and MP3 playback below the lesson, including long-text vertical scrolling.
- Close and reopen the app offline. Confirm Drift still resolves the exact published revision and the audio behaves according to its download/cache policy. Do not claim that MP3 remains playable offline if it was not cached.
- Exercise corrupted-MP3, interrupted-download, stale-revision and redownload paths.
- Keep a dated report listing concrete device, OS, Git SHA, release ID, content revision ID, MP3 checksum, screenshots/log excerpts and pass/fail results.

## Release blockers

- A failed CI gate or missing evidence at the exact SHA.
- Inability to consume published CURRENT content in Flutter/Drift after offline reopen.
- Missing real-store sandbox verification, purchase restore and refund/revocation acceptance for the lifetime unlock SKU.
- Unfinished mobile privacy, signing and physical-device/store-review checks.

Kokoro V2 is developed separately in draft PR #54; its K4 readiness is **not** implied by Piper B8 or A1 results. Do not enable it in production as part of this gate.

The operator evidence must be reviewed before moving from technical testing to commercial-release qualification.
