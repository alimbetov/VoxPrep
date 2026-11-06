# Importing a lesson with image and audio

XML v1 carries content fields and typed bodies. Binary images and MP3 files are not embedded in XML. Use the actual MVC workflow:

1. Open `/admin/imports`, upload `fixtures/reliable-backend-services.xml`, Validate, then Import as DRAFT.
2. Open the created revision. In Image assets, select/upload a cover from the media library and bind it.
3. Move the revision to READY_FOR_AUDIO.
4. In TTS audio review choose PRONUNCIATION and the active approved voice model, then Prepare / reuse TTS job.
5. Wait for READY and play the authenticated backend preview. Review/approval/publication are separate editorial actions.

`./scripts/local/import-media-example.sh` performs exactly those operations through HTTP forms and CSRF. SQL is read-only and used only to locate/check the revision and job. It refuses an existing `JAVA_RELIABLE_SERVICES_01` code, preserving existing content. It requires the local backend, working Worker, an active `en_US.ljspeech.medium` model and the tracked demo cover. The script validates the uploaded cover bytes and MP3 format, saves evidence under ignored `artifacts/local-smoke/xml-media-*/`, and never approves or publishes.

Local result 2026-11-06:

- Revision: `b5e6c3a6-a305-4308-ad44-8dab1b13a791`, phrase `JAVA_RELIABLE_SERVICES_01`, revision 1.
- Cover asset: `d4580a4a-b997-447b-b69f-ccdb5e5405bf`.
- Piper job: `9d1588ba-18de-417a-b330-3bf499ad9bfa`, READY, one attempt.
- Audio asset: `33173da7-8c53-4b04-bf23-28edff8b92b1`, MP3, 24000 Hz, 8.184 seconds.
- MP3 SHA-256: `dd5269245ea5e650fd840cf8778fd6a6f3c82af0167e22faa6f10638c07713a5`.
- Lifecycle remains READY_FOR_AUDIO. The material is visible in Content Studio; learner HTTP/Flutter requires subsequent editorial approval, catalogue/pack membership and publication.
