--liquibase formatted sql

--changeset voxprep:k1-kokoro-0001-expand-tts-engine
-- Expand the enum-like CHECK while old Piper workers are fenced to PIPER in both claim queries.
-- No Kokoro jobs may be enrolled until V2 authorization, manifest and routing are qualified.
SET ROLE voxprep_owner;
ALTER TABLE app.tts_voice_model
    DROP CONSTRAINT ck_tts_voice_model__engine;
ALTER TABLE app.tts_voice_model
    ADD CONSTRAINT ck_tts_voice_model__engine
    CHECK (engine IN ('PIPER', 'KOKORO'));
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback ALTER TABLE app.tts_voice_model DROP CONSTRAINT ck_tts_voice_model__engine;
--rollback ALTER TABLE app.tts_voice_model ADD CONSTRAINT ck_tts_voice_model__engine CHECK (engine IN ('PIPER'));
--rollback RESET ROLE;
