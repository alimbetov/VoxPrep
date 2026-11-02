--liquibase formatted sql

--changeset voxprep:b1-p8-0001-link-tts-model-assets
SET ROLE voxprep_owner;
ALTER TABLE app.tts_voice_model
    ADD CONSTRAINT fk_tts_voice_model__model_asset FOREIGN KEY (model_asset_id)
        REFERENCES app.file_asset (id) ON DELETE RESTRICT,
    ADD CONSTRAINT fk_tts_voice_model__config_asset FOREIGN KEY (config_asset_id)
        REFERENCES app.file_asset (id) ON DELETE RESTRICT;
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback ALTER TABLE app.tts_voice_model DROP CONSTRAINT fk_tts_voice_model__config_asset;
--rollback ALTER TABLE app.tts_voice_model DROP CONSTRAINT fk_tts_voice_model__model_asset;
--rollback RESET ROLE;

--changeset voxprep:b1-p8-0002-guard-tts-model-assets-function splitStatements:false
SET ROLE voxprep_owner;
CREATE FUNCTION app.tts_voice_model_asset_guard()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    model_kind varchar(32);
    model_status varchar(32);
    model_hash varchar(64);
    config_kind varchar(32);
    config_status varchar(32);
    config_hash varchar(64);
BEGIN
    SELECT kind, status, sha256
      INTO model_kind, model_status, model_hash
      FROM app.file_asset
     WHERE id = NEW.model_asset_id;

    SELECT kind, status, sha256
      INTO config_kind, config_status, config_hash
      FROM app.file_asset
     WHERE id = NEW.config_asset_id;

    IF model_kind IS DISTINCT FROM 'TTS_MODEL'
       OR model_hash IS DISTINCT FROM NEW.model_sha256 THEN
        RAISE EXCEPTION 'TTS model asset identity does not match voice model'
            USING ERRCODE = '23514';
    END IF;

    IF config_kind IS DISTINCT FROM 'TTS_CONFIG'
       OR config_hash IS DISTINCT FROM NEW.config_sha256 THEN
        RAISE EXCEPTION 'TTS config asset identity does not match voice model'
            USING ERRCODE = '23514';
    END IF;

    IF NEW.status IN ('APPROVED', 'ACTIVE', 'DEPRECATED')
       AND (model_status IS DISTINCT FROM 'READY' OR config_status IS DISTINCT FROM 'READY') THEN
        RAISE EXCEPTION 'Approved TTS voice model requires READY model and config assets'
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP FUNCTION app.tts_voice_model_asset_guard();
--rollback RESET ROLE;

--changeset voxprep:b1-p8-0003-guard-tts-model-assets-trigger
SET ROLE voxprep_owner;
CREATE TRIGGER trg_tts_voice_model_asset_guard
BEFORE INSERT OR UPDATE OF model_asset_id, config_asset_id, model_sha256, config_sha256, status
ON app.tts_voice_model
FOR EACH ROW
EXECUTE FUNCTION app.tts_voice_model_asset_guard();
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TRIGGER trg_tts_voice_model_asset_guard ON app.tts_voice_model;
--rollback RESET ROLE;
