--liquibase formatted sql

--changeset voxprep:b1-p11-0001-add-tts-audio-metadata
SET ROLE voxprep_owner;
ALTER TABLE app.file_asset
    ADD COLUMN audio_profile varchar(128),
    ADD COLUMN duration_ms bigint,
    ADD CONSTRAINT ck_file_asset__audio_profile CHECK (
        audio_profile IS NULL OR (audio_profile = btrim(audio_profile) AND char_length(audio_profile) > 0)),
    ADD CONSTRAINT ck_file_asset__duration_ms CHECK (duration_ms IS NULL OR duration_ms >= 1),
    ADD CONSTRAINT ck_file_asset__audio_metadata CHECK (
        (kind = 'TTS_AUDIO')
        OR (audio_profile IS NULL AND duration_ms IS NULL)),
    ADD CONSTRAINT ck_file_asset__duration_profile CHECK (
        duration_ms IS NULL OR audio_profile IS NOT NULL);
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback ALTER TABLE app.file_asset DROP CONSTRAINT ck_file_asset__duration_profile;
--rollback ALTER TABLE app.file_asset DROP CONSTRAINT ck_file_asset__audio_metadata;
--rollback ALTER TABLE app.file_asset DROP CONSTRAINT ck_file_asset__duration_ms;
--rollback ALTER TABLE app.file_asset DROP CONSTRAINT ck_file_asset__audio_profile;
--rollback ALTER TABLE app.file_asset DROP COLUMN duration_ms;
--rollback ALTER TABLE app.file_asset DROP COLUMN audio_profile;
--rollback RESET ROLE;
