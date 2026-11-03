# MVC-R3 Content Forms

## R3.1 — Draft list and editor

This slice wires the server-rendered Content Studio to the existing content application services.

Scope:
- `/admin/content` lists content revisions through `ContentAdminQueryService`.
- `/admin/content/revisions/{id}/edit` renders a type-aware editor for all seven content types.
- POST updates use `ContentAuthoringService.updateDraft` and preserve optimistic locking via `expectedVersion`.
- `ContentType` is immutable at the MVC boundary.
- SHA-256 is derived server-side from canonical form state; editors do not enter checksums manually.
- CSRF remains mandatory for state-changing MVC requests.
- content not-found and authoring conflicts map to the shared safe 404/409 Content Studio boundary.

Body text conventions used by the initial no-JavaScript editor:
- lists: one value per line;
- topic sections: `heading|text`;
- shadowing segments: `startMs|endMs|text`;
- question options: `key|true|text`;
- practice-test question IDs: one UUID per line.

Out of scope for R3.1:
- lifecycle transitions (`READY_FOR_AUDIO`, review, approval);
- creating a new logical content item;
- localization authoring;
- publication orchestration.

Those remain separate slices so the draft editor does not bypass the existing lifecycle services.
