# Universal Vertical Catalogue — Manifest Schema v2

**Date:** 2026-10-31  
**Branch:** `feat/universal-vertical-catalogue`  
**Status:** normative V4 contract delta.

## Purpose

Manifest schema v2 extends the existing C4 immutable publication snapshot. It does not create a second learner catalogue source and does not replace the atomic CURRENT switch. The root manifest remains the single publication truth path.

## Compatibility

- Flutter app contract is raised to version `2`.
- The client continues to read root manifest schema `1` during migration.
- Root manifest schema `2` is accepted only when `minimumAppContractVersion >= 2`.
- Schema versions greater than `2` fail closed with `SCHEMA_UNSUPPORTED`.

## Required universal catalogue membership

Every schema-v2 root snapshot MUST contain exactly one exact revision for each core catalogue kind:

1. `vertical-sections`
2. `verticals`
3. `vertical-presentation`
4. `learning-goals`
5. `learning-tracks`
6. `learning-collections`

Each entry is immutable and exact by:

```text
kind + revision + checksum
```

The existing uniqueness rule forbids two revisions of the same catalogue kind in one root snapshot. Additional supported catalogues such as categories, skills, levels, locales and voices MAY be members of the same snapshot.

## Atomic visibility

The lifecycle remains:

```text
Backend publication
  -> immutable root manifest v2
  -> exact catalogue payload download
  -> checksum/decoder/graph validation
  -> staged local snapshot
  -> one atomic CURRENT switch
  -> learner-visible repository reads
```

A partial, failed or restarted staging operation MUST NOT expose a mixture of catalogue revisions. The previous CURRENT snapshot remains authoritative until the complete new snapshot has been validated and committed.

## Collection membership

`learning-collections` contains the ordered `members[]` contract frozen in `UNIVERSAL_VERTICAL_CATALOGUE_CONTRACT_FREEZE_V1_1.md`. Reordering or replacing an exact Content/Test member changes the immutable catalogue payload and checksum, so it becomes visible only as a new exact catalogue revision in a later CURRENT snapshot.

## Locale materialization

Locale selection may project pack variants only. It MUST preserve root `practiceTests` and `catalogues` membership byte-for-byte at the domain-reference level. Universal catalogue ownership is therefore independent of locale and remains attached to one publication snapshot.

## Acceptance

V4 is accepted only when tests demonstrate:

- schema v1 remains readable;
- complete schema v2 is readable;
- incomplete schema v2 fails closed;
- schema v2 with app contract below 2 fails closed;
- schema v3 fails as unsupported;
- duplicate catalogue kind fails;
- locale materialization preserves all exact catalogue references;
- existing C4 atomic CURRENT semantics remain the only learner visibility switch.
