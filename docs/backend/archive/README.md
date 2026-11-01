# Backend Documentation Archive

This directory is reserved for historical backend documentation that is no longer a normative design input for CareerSpeak v1.

Canonical documentation lives in:

```text
docs/backend/v1/
```

## What belongs here

Move documents here when they are useful only for:

```text
decision history
gap-analysis rationale
old remediation plans
superseded roadmaps
qualification evidence tied to old branches/SHA
implementation slices that are no longer current design guidance
```

## What must not be archived

Do not archive active machine-consumed fixtures/contracts or current reference material still required by CI until their consumers are migrated.

## Deletion policy

Historical documents should normally be archived rather than deleted immediately.

Delete a legacy document only when:

```text
its information is fully represented in canonical v1 docs or Git history
no active repository link depends on its path
no CI/test/tool consumes it
no unresolved decision references it
```

Git history remains the final record, but the archive keeps architectural rationale discoverable without polluting the active design set.