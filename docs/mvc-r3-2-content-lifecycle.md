# MVC-R3.2 Content Lifecycle

R3.2 adds state-driven lifecycle actions to the server-rendered Content Studio without bypassing `ContentAuthoringService`.

Supported authoring flow:

`DRAFT -> READY_FOR_AUDIO -> READY_FOR_REVIEW -> APPROVED`

Controls are rendered only for the current legal next state. Published/archived workflow remains owned by the publication slice.

Actions:
- DRAFT: mark ready for audio;
- READY_FOR_AUDIO: submit for review with optional reason/comment;
- READY_FOR_REVIEW: approve with optional reason/comment;
- APPROVED/PUBLISHED/ARCHIVED: create the next DRAFT revision from the latest frozen revision.

Security and consistency:
- every POST requires CSRF;
- every command carries `expectedVersion`;
- reviewer/approver actor comes from `Authentication.getName()` and is never accepted from the form;
- illegal lifecycle transitions and stale writes use the existing safe HTTP 409 Content Studio boundary;
- review/approval continues to append the existing audit records through `ContentAuthoringService`.

Out of scope:
- publish/archive actions;
- TTS worker orchestration;
- localization lifecycle;
- direct persistence mutation from MVC.
