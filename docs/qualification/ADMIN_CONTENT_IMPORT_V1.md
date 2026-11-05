# VoxPrep Content Studio — JSON/XML typed import v1

Scope: administrator-only **new DRAFT revision 1** import. It is separate
from DEV test fixtures and from publication. Requires an authenticated ADMIN,
CSRF and a valid upload (max 256 KiB, 100 records).

## User workflow

1. Open `/admin/imports`, choose a JSON or XML document.
2. **Preview / Validate**: parse with the normal typed-content mapper and
   check current exact identities without persisting. Every entry is shown
   with code, type, title and `New draft` or `Exists — skip`.
3. Select the same file again and click **Import as drafts**. The server
   requires the exact SHA-256 digest from the preview in the same admin
   session; it reparses and validates the file.
4. All new records are written transactionally through
   `ContentAuthoringService.createInitialRevision`, no direct SQL and no
   update to existing revision 1.
5. Continue in `/admin/content` with media/TTS, localization, review,
   approval and publication. **Import never publishes or grants FULL.**

## JSON example (complete typed PHRASE)

```json
{
  "schemaVersion": 1,
  "items": [
    {
      "contentCode": "GREETING_SAMPLE_001",
      "bodyType": "phrase",
      "title": "Asking for clarification",
      "subtitle": "Professional communication",
      "description": "Polite questions in a meeting",
      "categoryCode": "COMMUNICATION",
      "levelCode": "B1",
      "minutes": 4,
      "availability": "ACTIVE",
      "skillCodes": ["SPEAKING"],
      "body": {
        "phrase": "Could you clarify that?",
        "usage": "Ask for more detail before answering.",
        "examples": ["Could you clarify the requirement?"]
      }
    }
  ]
}
```

Supported `bodyType` values match the existing Content Studio editor:
`vocabulary`, `interview`, `topic`, `phrase`, `shadowing`,
`question`, `practice_test`. Each must provide the exact type-specific
fields; the importer does **not** fill missing questions/answers/text with
placeholders. Structured JSON examples:

```json
{
  "vocabulary": {"term":"resilient","definition":"Able to recover quickly","partOfSpeech":"adjective","examples":["A resilient service recovers."]},
  "interview": {"prompt":"Explain DI","modelAnswer":"Dependencies are injected.","keyPoints":["Testability","Low coupling"]},
  "topic": {"sections":[{"heading":"Overview","text":"A complete topic explanation."}]},
  "shadowing": {"transcript":"The service recovered.","segments":[{"startMs":0,"endMs":2000,"text":"The service recovered."}]},
  "question": {"questionText":"Which is correct?","explanation":"Explain the answer.","options":[{"key":"A","correct":true,"text":"Option one"},{"key":"B","correct":false,"text":"Option two"}]},
  "practice_test": {"instructions":"Complete each question.","passingScorePercent":70,"questionRevisionIds":["00000000-0000-0000-0000-000000000001"]}
}
```

The above block illustrates **individual body objects**, not an import
document. All records need the common metadata fields in the full example.

## XML example (complete typed PHRASE)

```xml
<voxprepImport schemaVersion="1">
  <item contentCode="GREETING_SAMPLE_002" bodyType="phrase">
    <title>Asking for clarification</title>
    <subtitle>Professional communication</subtitle>
    <description>Polite questions in a meeting</description>
    <categoryCode>COMMUNICATION</categoryCode>
    <levelCode>B1</levelCode>
    <minutes>4</minutes>
    <availability>ACTIVE</availability>
    <skillCodes><value>SPEAKING</value></skillCodes>
    <body>
      <phrase>Could you clarify that?</phrase>
      <usage>Ask for more detail before answering.</usage>
      <examples><value>Could you clarify the requirement?</value></examples>
    </body>
  </item>
</voxprepImport>
```

In XML, arrays use `<value>` for strings and `<item>` with matching
child elements for structured sections, segments and options. XML DTD,
external entities and XInclude are rejected.

## Not part of this slice

- Revision 2+ merge/upsert/overwrite of already approved material.
- Direct publishing or creation of the collection hierarchy, membership,
  images, media or TTS jobs.
- Automatic localization of imported content.
- Resolving arbitrary question UUIDs to actual published question revisions.

Those transitions must remain explicit and independently qualified. A
successful import does **not** prove full Flutter publication acceptance.
