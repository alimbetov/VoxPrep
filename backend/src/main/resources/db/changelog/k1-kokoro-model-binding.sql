--liquibase formatted sql

--changeset voxprep:k1-kokoro-0004-model-bundle-voice-binding splitStatements:false
-- Bind each Kokoro voice-model record to an already staged immutable bundle
-- and one of the three verified educational voice styles. Do not modify Piper.
SET ROLE voxprep_owner;
CREATE TABLE app.tts_kokoro_model_binding (
    voice_model_id uuid PRIMARY KEY
        REFERENCES app.tts_voice_model(id) ON DELETE RESTRICT,
    bundle_id uuid NOT NULL
        REFERENCES app.tts_kokoro_bundle(id) ON DELETE RESTRICT,
    voice_code varchar(64) NOT NULL,
    voice_artifact_path varchar(256) NOT NULL,
    phonemizer_version varchar(128) NOT NULL,
    default_speed numeric(5,3) NOT NULL DEFAULT 1.000,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_tts_kokoro_binding_voice CHECK (
        (voice_code = 'af_heart' AND voice_artifact_path = 'voices/af_heart.bin') OR
        (voice_code = 'am_michael' AND voice_artifact_path = 'voices/am_michael.bin') OR
        (voice_code = 'bf_emma' AND voice_artifact_path = 'voices/bf_emma.bin')
    ),
    CONSTRAINT ck_tts_kokoro_binding_speed CHECK (default_speed BETWEEN 0.500 AND 2.000),
    CONSTRAINT fk_tts_kokoro_binding_artifact FOREIGN KEY
        (bundle_id, voice_artifact_path)
        REFERENCES app.tts_kokoro_bundle_artifact(bundle_id, logical_path)
        ON DELETE RESTRICT
);
CREATE FUNCTION app.tts_kokoro_binding_immutable() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NOT EXISTS (
            SELECT 1 FROM app.tts_voice_model vm
             WHERE vm.id = NEW.voice_model_id AND vm.engine = 'KOKORO'
        ) THEN
            RAISE EXCEPTION 'Kokoro binding requires KOKORO voice model'
                USING ERRCODE = '23514';
        END IF;
        RETURN NEW;
    END IF;
    RAISE EXCEPTION 'Kokoro voice bundle bindings are immutable'
        USING ERRCODE = '23514';
END;
$$;
CREATE TRIGGER trg_tts_kokoro_binding_immutable
BEFORE INSERT OR UPDATE OR DELETE ON app.tts_kokoro_model_binding
FOR EACH ROW EXECUTE FUNCTION app.tts_kokoro_binding_immutable();
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TRIGGER trg_tts_kokoro_binding_immutable ON app.tts_kokoro_model_binding;
--rollback DROP FUNCTION app.tts_kokoro_binding_immutable();
--rollback DROP TABLE app.tts_kokoro_model_binding;
--rollback RESET ROLE;
