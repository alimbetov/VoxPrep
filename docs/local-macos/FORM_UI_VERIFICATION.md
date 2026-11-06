# Content Studio form verification

Actual Mac browser run: 2026-11-05, approximately 22:00–22:09 Asia/Almaty.
Initial UI checks used application code from `a2a4208c` (test-only HEAD `08ad6e16`).
Fixes and final HTTP/UI recheck used application SHA
`6c422ffbfb9183af7002810225ae27e3232874a3`.
This is a scoped form regression report, not a new full-stack qualification.

## Browser checks

| Form / operation | Result |
|---|---|
| Empty vertical submit | PASS: required fields rejected, form remains open |
| Vertical with lowercase code and surrounding spaces | PASS: saved as QA_UI_20261105_V1, section QA_TECH |
| Media picker during vertical creation | PASS: selected preview appears, typed fields preserved |
| Vertical edit / reload | PASS: title change saved, code read-only, icon retained, INACTIVE retained |
| Goal with internal code space and sort order -1 | PASS: both rejected; title/description preserved |
| Goal correction and submit | PASS: code normalized, Cyrillic title/description saved |
| Track with level ` b2 ` and blank optional career code | PASS: B2 saved, optional career code null |
| Collection create FULL | PASS: FULL shown after save and on edit |
| Collection edit FREE | PASS: FREE and edited title persisted |
| Phrase create with minutes 0 | PASS: browser validation blocks submission |
| Phrase create with minutes 2 | PASS: exact revision 1 created as DRAFT |
| Add/reorder phrase examples | PASS: order persisted after Save draft and reload |
| Cover binding with unsaved title/examples | PASS: text and order retained; subsequent save succeeds |
| Saved DRAFT cover preview | PASS after fix: actual bound image remains visible on reload |
| Success notification | PASS after fix: one message after save |

QA fixtures were created through browser forms. The QA vertical is INACTIVE,
the material remains DRAFT, and CURRENT remains contentVersion 3. No QA material
was approved/published. User-entered forms were not submitted by this verification.

## Fixes found during the browser run

- A bound image disappeared visually after saving/reloading the editor. The
  controller now loads existing image bindings through the read-only media query;
  saved previews show on DRAFT and frozen revisions. Changing an image updates the
  existing role preview without leaving an outdated duplicate.
- Success messages appeared twice because both the shell and child template
  rendered the flash message. The shared shell now renders it once.
- Catalogue field labels now explicitly point to their inputs. A saved vertical
  icon is labelled “Image selected” on subsequent loads.

Existing `R5AdminHttpPublicationWorkflow` now asserts that the bound asset preview
is present when reopening the editor. That broader R5 suite was not executed in
this run; its new assertion is committed for subsequent qualification.

## Verification and evidence

```bash
source scripts/local/java-env.sh
mvn -B -ntp -f backend/pom.xml \
  -Dtest=MediaPickerControllerTest,CatalogueMvcFormsTest,StudioAccessDeniedHandlerTest test
```

Result: **5 tests, 0 failures/errors/skips**, exit 0. Live HTTP recheck after fixes
opened all four persisted catalogue forms with HTTP 200, checked B2 and FREE,
then saved only the QA phrase DRAFT and verified one success message plus its
stored image preview. Read-only SQL confirmed hierarchy parents, normalized
codes, INACTIVE vertical, FREE collection and DRAFT material.

Local evidence: `artifacts/local-smoke/forms-ui/`:

- `regression-tests.log` — targeted test results.
- `recheck.json` — HTTP recheck with timestamp, application SHA and scope note.
- `database.json` — read-only SQL snapshot of QA values and CURRENT.
- `catalogue-created.jpg`, `catalogue-final.jpg` — saved hierarchy.
- `cover-persisted.jpg` — saved image preview after reopening.

Fixture identities:

| Entity | UUID |
|---|---|
| Vertical | `79cedb70-4248-4724-8d78-c6bcf12f88df` |
| Goal | `9d1fceeb-4cb0-4a0a-8aad-4693132b1c31` |
| Track | `362bbd09-844a-4f02-a243-18c41a61cb4e` |
| Collection | `c8f4b5d7-8599-4941-96b0-02c956b3d274` |
| Phrase DRAFT | `f09287ee-75e1-4103-a34a-876e30a20387` |

Not covered here: every content body type, exhaustive length boundaries, duplicate
submission/concurrency, localization lifecycle or new publication. The earlier
A2 acceptance report remains evidence for its own exact SHA only.
