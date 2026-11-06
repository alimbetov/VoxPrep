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
