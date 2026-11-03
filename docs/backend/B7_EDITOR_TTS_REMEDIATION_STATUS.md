# B7 Editor / TTS Remediation Status

## Current implementation slice

### TTS-R1 — typed audio policy

Status: IMPLEMENTED, qualification pending.

Implemented:

```text
ContentAudioRole
AudioRequirement
ContentAudioPolicyEntry
ContentAudioPolicy
ContentAudioPolicyTest
```

Normative roles:

```text
VOCABULARY  pronunciation  OPTIONAL
PHRASE      pronunciation  RECOMMENDED
INTERVIEW   question       RECOMMENDED
INTERVIEW   sampleAnswer   RECOMMENDED
TOPIC       narration      OPTIONAL
SHADOWING   shadowing      REQUIRED
```

`QUESTION` and `PRACTICE_TEST` are fail-closed for TTS v1.

The test matrix evaluates every current `ContentType × ContentAudioRole` combination.

## Learner media clarification

B7 completion is defined by the learner-visible aggregate:

```text
exact published text
+ deterministic localization
+ publication-scoped audio assets
+ publication-scoped image assets
```

TTS-R4 therefore must use a generic content→FileAsset binding capable of representing audio and images, while audio semantics remain governed by `ContentAudioPolicy`.
