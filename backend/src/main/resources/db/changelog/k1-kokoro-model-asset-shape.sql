--liquibase formatted sql

--changeset voxprep:k1-kokoro-0006-engine-specific-model-assets
-- Piper keeps its mandatory model/config file pair. Kokoro uses the separate
-- append-only bundle binding instead. Historical Piper rows are untouched.
SET ROLE voxprep_owner;
ALTER TABLE app.tts_voice_model
  ALTER COLUMN model_asset_id DROP NOT NULL,
  ALTER COLUMN config_asset_id DROP NOT NULL,
  ALTER COLUMN model_sha256 DROP NOT NULL,
  ALTER COLUMN config_sha256 DROP NOT NULL;
ALTER TABLE app.tts_voice_model ADD CONSTRAINT ck_tts_voice_model__engine_assets CHECK (
   (engine = 'PIPER' AND model_asset_id IS NOT NULL AND config_asset_id IS NOT NULL
      AND model_sha256 IS NOT NULL AND config_sha256 IS NOT NULL)
   OR
   (engine = 'KOKORO' AND model_asset_id IS NULL AND config_asset_id IS NULL
      AND model_sha256 IS NULL AND config_sha256 IS NULL)
);
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback ALTER TABLE app.tts_voice_model DROP CONSTRAINT ck_tts_voice_model__engine_assets;
--rollback ALTER TABLE app.tts_voice_model ALTER COLUMN model_asset_id SET NOT NULL;
--rollback ALTER TABLE app.tts_voice_model ALTER COLUMN config_asset_id SET NOT NULL;
--rollback ALTER TABLE app.tts_voice_model ALTER COLUMN model_sha256 SET NOT NULL;
--rollback ALTER TABLE app.tts_voice_model ALTER COLUMN config_sha256 SET NOT NULL;
--rollback RESET ROLE;

--changeset voxprep:k1-kokoro-0007-engine-aware-asset-guard splitStatements:false
SET ROLE voxprep_owner;
CREATE OR REPLACE FUNCTION app.tts_voice_model_asset_guard()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    model_kind varchar(32);
    model_status varchar(32);
    model_hash varchar(64);
    config_kind varchar(32);
    config_status varchar(32);
    config_hash varchar(64);
BEGIN
    IF NEW.engine = 'KOKORO' THEN
        IF NEW.model_asset_id IS NOT NULL OR NEW.config_asset_id IS NOT NULL
            OR NEW.model_sha256 IS NOT NULL OR NEW.config_sha256 IS NOT NULL THEN
            RAISE EXCEPTION 'Kokoro models require pinned bundles, not Piper assets'
                USING ERRCODE = '23514';
        END IF;
        RETURN NEW;
    END IF;
    SELECT kind, status, sha256 INTO model_kind, model_status, model_hash
      FROM app.file_asset WHERE id = NEW.model_asset_id;
    SELECT kind, status, sha256 INTO config_kind, config_status, config_hash
      FROM app.file_asset WHERE id = NEW.config_asset_id;
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
--rollback not supported: restore original Piper-only asset guard from b1-p8-tts-model-assets.sql after all Kokoro rows are removed
