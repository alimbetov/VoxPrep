# CareerSpeak TTS Voice Catalog V1

Status: **PRODUCTION BASELINE**  
Normative machine-readable source: `contracts/tts-voice-catalog-v1.yaml`

## Purpose

This document freezes the V1 Piper voice selection used by CareerSpeak/VoxPrep backend provisioning and TTS job creation. It does not replace immutable `tts_voice_model` artifact identity. Exact model/config revision, SHA-256 digests, and sizes are pinned when a model is provisioned and persisted.

The V1 English policy is intentionally narrow:

- `en_US` uses **`lessac` / `high`** and is the default production voice.
- `en_GB` uses **`cori` / `high`**.
- No other English voice may be selected by silent fallback or substitution in V1.

## Production catalog

| Locale | Voice | Quality | Model ID | Role | Provisioning | Enabled |
| --- | --- | --- | --- | --- | --- | --- |
| `en_US` | `lessac` | high | `en_US-lessac-high` | Primary US English | `STRICT` | yes |
| `en_GB` | `cori` | high | `en_GB-cori-high` | British English | `ENSURE_PRESENT` | yes |
| `de_DE` | `thorsten` | high | `de_DE-thorsten-high` | German | `STRICT` | yes |
| `tr_TR` | `dfki` | medium | `tr_TR-dfki-medium` | Turkish | `STRICT` | yes |
| `es_MX` | `claude` | high | `es_MX-claude-high` | LATAM Spanish | `STRICT` | yes |
| `es_ES` | `davefx` | medium | `es_ES-davefx-medium` | Spain Spanish | `STRICT` | yes |
| `fr_FR` | `siwis` | medium | `fr_FR-siwis-medium` | French | `ENSURE_PRESENT` | yes |
| `it_IT` | `serena` | high | `it_IT-serena-high` | Italian | `ENSURE_PRESENT` | yes |
| `pt_BR` | `faber` | medium | `pt_BR-faber-medium` | Brazilian Portuguese | `ENSURE_PRESENT` | yes |
| `ru_RU` | `irina` | medium | `ru_RU-irina-medium` | Russian | `ENSURE_PRESENT` | yes |
| `kk_KZ` | `issai` | high | `kk_KZ-issai-high` | Kazakh | `ENSURE_PRESENT` | yes |
| `uk_UA` | `tetiana` | high | `uk_UA-tetiana-high` | Ukrainian | `DISABLED` | no |

### Kazakh speaker binding

`kk_KZ-issai-high` is a multi-speaker Piper model. V1 pins `speakerId: 0` (`ISSAI_KazakhTTS2_M2`) so synthesis is deterministic. A future speaker change is a catalog revision and must not be introduced as an implicit runtime fallback.

## Provisioning semantics

### `STRICT`

A `STRICT` model is a production-readiness dependency. The exact pinned model and config must be present and integrity-verified before the deployment is considered production-ready. Missing, unreadable, checksum-mismatched, or identity-mismatched artifacts fail closed.

### `ENSURE_PRESENT`

The provisioning/reconciliation path must make the exact model available. Application startup does not have to eagerly load the model, but synthesis is allowed only after the pinned model/config have been resolved and integrity-verified. Missing models fail the request/job; they never cause voice substitution.

### `DISABLED`

The catalog entry is reserved, but it is excluded from provisioning, automatic selection, and synthesis. Enabling it requires an explicit catalog revision and the normal artifact-pinning qualification.

## Domain mapping

The contract is mapped into the existing TTS domain as follows:

1. `tts_voice` owns the logical locale/voice/quality selection and enabled/provisioning policy.
2. `tts_voice_model` owns the immutable exact artifact identity for that selection.
3. `modelId` is the Piper model identity; it is not sufficient by itself for production integrity.
4. Every enabled model must have an immutable model revision, model/config SHA-256, and model/config sizes persisted before it becomes synthesis-eligible.
5. For a multi-speaker model, `speakerId` is part of the effective synthesis identity and fingerprint.
6. TTS jobs bind to an exact `voice_model_id`; the Worker must not substitute a different voice, quality, locale, model revision, or speaker.

## Required B1 bootstrap behavior

The Backend B1 voice/model bootstrap must:

1. parse and validate `contracts/tts-voice-catalog-v1.yaml`;
2. reject duplicate locales or duplicate `modelId` values;
3. verify that the default locale/model are enabled and present;
4. reconcile `STRICT` and `ENSURE_PRESENT` entries according to their policy;
5. mirror or otherwise provision the exact model/config artifacts through the approved model supply path;
6. compute and persist SHA-256 digests and byte sizes in immutable `tts_voice_model` records;
7. require explicit speaker binding for multi-speaker models;
8. reject `DISABLED` models from job creation;
9. fail closed on any artifact or identity mismatch.

Production promotion must also complete the model-card/license review for every provisioned upstream artifact. Live upstream metadata is discovery input, not a runtime source of truth; production builds should qualify against pinned/mirrored artifacts.

## V1 invariants

- `en_US-lessac-high` is the default model.
- `en_GB-cori-high` is the only V1 British English model.
- Locale and `modelId` values are unique in the catalog.
- `DISABLED` implies `enabled: false`.
- Enabled models require immutable artifact pinning before synthesis.
- There is no silent voice substitution.
- There is no cross-locale TTS fallback.
- There is no quality downgrade fallback.
- Model/config checksum failure is terminal for the attempted synthesis path.
- A catalog/model change must be explicit and versioned.

## Qualification target

The catalog is considered implementation-ready for B1 when automated validation proves the YAML invariants and the provisioning qualification proves that every enabled V1 model can be resolved to an approved, immutable `tts_voice_model` artifact record. `uk_UA-tetiana-high` is intentionally excluded from that enabled-model qualification until explicitly activated.
