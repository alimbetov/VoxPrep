--liquibase formatted sql

--changeset voxprep:b5-p1-0001-add-tts-model-provenance
SET ROLE voxprep_owner;
ALTER TABLE app.tts_voice_model
    ADD COLUMN source_provider varchar(64),
    ADD COLUMN source_repository varchar(256),
    ADD COLUMN source_revision varchar(128);

ALTER TABLE app.tts_voice_model
    ADD CONSTRAINT ck_tts_voice_model__source_provider
        CHECK (source_provider IS NULL OR (source_provider = btrim(source_provider) AND char_length(source_provider) > 0)),
    ADD CONSTRAINT ck_tts_voice_model__source_repository
        CHECK (source_repository IS NULL OR (source_repository = btrim(source_repository) AND char_length(source_repository) > 0)),
    ADD CONSTRAINT ck_tts_voice_model__source_revision
        CHECK (source_revision IS NULL OR (source_revision = btrim(source_revision) AND char_length(source_revision) > 0));
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback ALTER TABLE app.tts_voice_model DROP CONSTRAINT ck_tts_voice_model__source_revision;
--rollback ALTER TABLE app.tts_voice_model DROP CONSTRAINT ck_tts_voice_model__source_repository;
--rollback ALTER TABLE app.tts_voice_model DROP CONSTRAINT ck_tts_voice_model__source_provider;
--rollback ALTER TABLE app.tts_voice_model DROP COLUMN source_revision;
--rollback ALTER TABLE app.tts_voice_model DROP COLUMN source_repository;
--rollback ALTER TABLE app.tts_voice_model DROP COLUMN source_provider;
--rollback RESET ROLE;

--changeset voxprep:b5-p1-0002-guard-tts-model-provenance splitStatements:false
SET ROLE voxprep_owner;
CREATE OR REPLACE FUNCTION app.tts_voice_model_immutable_identity_guard()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.code IS DISTINCT FROM OLD.code
       OR NEW.voice_id IS DISTINCT FROM OLD.voice_id
       OR NEW.engine IS DISTINCT FROM OLD.engine
       OR NEW.engine_version IS DISTINCT FROM OLD.engine_version
       OR NEW.model_version IS DISTINCT FROM OLD.model_version
       OR NEW.model_asset_id IS DISTINCT FROM OLD.model_asset_id
       OR NEW.config_asset_id IS DISTINCT FROM OLD.config_asset_id
       OR NEW.model_sha256 IS DISTINCT FROM OLD.model_sha256
       OR NEW.config_sha256 IS DISTINCT FROM OLD.config_sha256
       OR NEW.source_provider IS DISTINCT FROM OLD.source_provider
       OR NEW.source_repository IS DISTINCT FROM OLD.source_repository
       OR NEW.source_revision IS DISTINCT FROM OLD.source_revision THEN
        RAISE EXCEPTION 'TTS voice model execution identity is immutable'
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;
RESET ROLE;
--rollback SELECT 1;
