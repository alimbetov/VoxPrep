# Universal Vertical Catalogue — Technical Audit

**Branch:** `feat/universal-vertical-catalogue`  
**Scope:** Flutter universal catalogue, exact publication consumption, audio roles, local asset lifecycle, restart/recovery and mock qualification.  
**Audit date:** 2026-10-31

## 1. Audited production flows

```text
Backend publication contract
  -> exact RootContentManifest
  -> exact pack / catalogue / assessment revisions
  -> staging
  -> atomic CURRENT pointer
  -> Drift repositories
  -> generic Vertical -> Goal -> Track -> Collection UI
```

```text
ContentRevision
  -> exact ContentAssetRef(role)
  -> AssetCatalog
  -> AssetResolver
  -> verified local file or exact re-download
  -> audio player
```

```text
AUTO_CACHE audio
  -> access timestamp
  -> TTL eligibility
  -> safe local-byte eviction
  -> publication metadata retained
  -> next Play
  -> same exact asset downloaded again
  -> size/checksum verified
```

## 2. Audit matrix

| Area | Result | Evidence / hardening |
| --- | --- | --- |
| Root publication identity | PASS | exact version/checksum contract already enforced |
| Exact pack membership | PASS | pack revision/checksum validation and snapshot membership tests |
| Exact catalogue membership | PASS | universal catalogue graph is snapshot-scoped |
| Practice-test membership | PASS | exact revision/checksum refs |
| Atomic CURRENT visibility | PASS | staged/current fence tests |
| Tombstone interaction | PASS | staged tombstone cannot hide prior CURRENT content |
| Universal Vertical graph | PASS | backend-owned Vertical -> Goal -> Track -> Collection |
| Unknown future vertical | PASS by contract/tests | Flutter does not require a vertical enum |
| Audio role publication | PASS | typed QUESTION/SAMPLE_ANSWER/PRONUNCIATION/NARRATION/SHADOWING roles |
| Required SHADOWING audio | PASS | fail-closed publication validation |
| INTERVIEW role availability | FIXED | UI no longer renders a role button when that exact role is not published |
| Local audio cache retention | FIXED | schema v10 retention registry |
| Protected local media | FIXED | EXPLICIT_DOWNLOAD/PINNED cannot be downgraded by normal playback |
| Required-offline media | FIXED | excluded from ordinary automatic eviction |
| Old audio cleanup | FIXED | AUTO_CACHE audio is TTL-eligible |
| Re-download after cleanup | FIXED | acceptance proves evict -> next resolve -> source open -> verified local file |
| Playback vs cleanup failure | PASS | retention bookkeeping is best-effort and cannot make valid playback fail |
| Startup vs cleanup failure | PASS | cleanup is best-effort and cannot block last-known-good local UI |
| Offline/restart catalogue | PASS | existing V11 acceptance |
| Adversarial catalogue | PASS by test coverage | existing V12 suite; exact-SHA CI still required |
| Full demo graph | PASS by test coverage | existing mock graph qualification |
| Full regression | PENDING exact-SHA | workflow runs formatting, generation, analyze and full Flutter tests |

## 3. Defect ledger

### UVC-AUD-001 — no durable retention class

**Problem:** the normative retention specification defines `AUTO_CACHE`, `EXPLICIT_DOWNLOAD` and `PINNED`, but runtime previously persisted only asset files.

**Risk:** an age-based cleanup could not distinguish disposable cache from user-protected offline media.

**Fix:** schema v10 introduces `asset_cache_retention` with descriptor identity, retention class, cache/access timestamps and required-offline flag.

### UVC-AUD-002 — old audio could not be safely reclaimed

**Problem:** `AssetFileStore` had read/write operations only.

**Fix:** `AssetCacheEvictionStore` provides exact-descriptor local-byte eviction. Publication metadata and learner state are never deleted by this operation.

### UVC-AUD-003 — re-download after eviction was not explicitly qualified

**Fix:** acceptance test uses a real filesystem store and mock byte source:

```text
resolve(downloadIfMissing)
  -> source open #1
  -> verified MP3 cached
  -> advance clock beyond TTL
  -> cleanup removes local bytes
  -> resolve(downloadIfMissing)
  -> source open #2
  -> same checksum-addressed path restored
```

### UVC-AUD-004 — protected retention could be accidentally downgraded

**Fix:** ordinary resolver access records `AUTO_CACHE` only when no stronger class exists. Existing `EXPLICIT_DOWNLOAD` and `PINNED` survive subsequent playback.

### UVC-AUD-005 — INTERVIEW UI rendered phantom audio roles

**Problem:** `QUESTION` and `SAMPLE_ANSWER` are independently `RECOMMENDED`, but UI rendered both controls whenever `ContentItem.hasAudio` was true.

**Fix:** UI now discovers exact CURRENT role bindings from `AssetCatalogRepository` and renders only published roles.

### UVC-AUD-006 — cleanup could become a startup dependency

**Fix:** startup cleanup is deliberately best-effort. Cleanup failure never invalidates CURRENT publication and never blocks the local UI.

## 4. Audio retention policy

Default automatic audio TTL:

```text
90 days since last resolver access
```

This value is policy/configuration and is not part of immutable publication identity.

Automatic eviction is allowed only when all are true:

```text
retention_class = AUTO_CACHE
media_type starts with audio/
required_offline = false
last_accessed_at < cutoff
```

Automatic eviction must never remove:

```text
EXPLICIT_DOWNLOAD
PINNED
requiredOffline asset
learner progress
favorites
publication membership
asset catalogue metadata
```

## 5. Re-download invariant

Local eviction is not content deletion.

The durable contract remains:

```text
CURRENT publication
  -> exact assetId
  -> checksumSha256
  -> deliveryKey
```

After local bytes are reclaimed, `AssetResolver(downloadIfMissing)` resolves the same CURRENT descriptor. `AssetDownloadManager` fetches the same immutable resource and verifies both size and SHA-256 before playback.

Therefore:

```text
cache eviction != publication tombstone
cache eviction != backend asset deletion
cache eviction != learner-state deletion
```

## 6. Test gates

New targeted gates:

```text
test/application/asset_cache_retention_manager_test.dart
test/data/local/drift_asset_cache_retention_repository_test.dart
test/acceptance/audio_cache_eviction_redownload_acceptance_test.dart
test/app/audio_playback_providers_test.dart
```

Existing gates retained:

```text
demo full learning graph
offline/restart
adversarial catalogue
schema migration
production E2E
full flutter test
flutter analyze
dart format
generated Drift reproducibility
```

## 7. Deliberate remaining scope

These are not hidden defects in the current TTL implementation, but later storage-management capabilities:

1. quota-pressure eviction across all disposable media;
2. global LRU ordering after expired-cache cleanup;
3. user-facing explicit Download/Pin/Unpin commands;
4. role-specific persisted resume position for multi-track INTERVIEW audio;
5. real Backend -> CDN/RustFS end-to-end qualification.

Until explicit Download/Pin command surfaces are implemented, automatic cleanup remains conservative and only removes entries proven to be `AUTO_CACHE`.

## 8. Closure rule

Do not call this hardening production-qualified until one exact branch SHA passes:

```text
format
generated-code reproducibility
flutter analyze
full flutter test
V10 demo graph
V11 offline/restart
V12 adversarial
v1 -> v10 migration
retention unit tests
evict -> redownload acceptance
production E2E
```
