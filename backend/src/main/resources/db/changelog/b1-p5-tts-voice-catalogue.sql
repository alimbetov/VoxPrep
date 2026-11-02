--liquibase formatted sql

--changeset voxprep:b1-p5-0001-create-tts-voice
SET ROLE voxprep_owner;
CREATE TABLE app.tts_voice (
    id uuid NOT NULL,
    version bigint NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    code varchar(128) NOT NULL,
    display_name varchar(256) NOT NULL,
    language varchar(64) NOT NULL,
    accent varchar(128),
    gender varchar(64),
    style varchar(128),
    enabled boolean NOT NULL,
    default_model_id uuid,
    CONSTRAINT pk_tts_voice PRIMARY KEY (id),
    CONSTRAINT uk_tts_voice__code UNIQUE (code),
    CONSTRAINT ck_tts_voice__code CHECK (code = btrim(code) AND char_length(code) > 0),
    CONSTRAINT ck_tts_voice__display_name CHECK (display_name = btrim(display_name) AND char_length(display_name) > 0),
    CONSTRAINT ck_tts_voice__language CHECK (language = btrim(language) AND char_length(language) > 0),
    CONSTRAINT ck_tts_voice__accent CHECK (accent IS NULL OR (accent = btrim(accent) AND char_length(accent) > 0)),
    CONSTRAINT ck_tts_voice__gender CHECK (gender IS NULL OR (gender = btrim(gender) AND char_length(gender) > 0)),
    CONSTRAINT ck_tts_voice__style CHECK (style IS NULL OR (style = btrim(style) AND char_length(style) > 0))
);
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TABLE app.tts_voice;
--rollback RESET ROLE;

--changeset voxprep:b1-p5-0002-create-tts-voice-model
SET ROLE voxprep_owner;
CREATE TABLE app.tts_voice_model (
    id uuid NOT NULL,
    version bigint NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    code varchar(128) NOT NULL,
    voice_id uuid NOT NULL,
    engine varchar(32) NOT NULL,
    engine_version varchar(64) NOT NULL,
    model_version varchar(128) NOT NULL,
    model_asset_id uuid NOT NULL,
    config_asset_id uuid NOT NULL,
    model_sha256 varchar(64) NOT NULL,
    config_sha256 varchar(64) NOT NULL,
    status varchar(32) NOT NULL,
    license_name varchar(256),
    license_reference varchar(1024),
    commercial_use_reviewed boolean NOT NULL,
    approved_at timestamptz,
    CONSTRAINT pk_tts_voice_model PRIMARY KEY (id),
    CONSTRAINT uk_tts_voice_model__code UNIQUE (code),
    CONSTRAINT uk_tts_voice_model__id_voice UNIQUE (id, voice_id),
    CONSTRAINT fk_tts_voice_model__voice FOREIGN KEY (voice_id)
        REFERENCES app.tts_voice (id) ON DELETE RESTRICT,
    CONSTRAINT ck_tts_voice_model__code CHECK (code = btrim(code) AND char_length(code) > 0),
    CONSTRAINT ck_tts_voice_model__engine CHECK (engine IN ('PIPER')),
    CONSTRAINT ck_tts_voice_model__engine_version CHECK (engine_version = btrim(engine_version) AND char_length(engine_version) > 0),
    CONSTRAINT ck_tts_voice_model__model_version CHECK (model_version = btrim(model_version) AND char_length(model_version) > 0),
    CONSTRAINT ck_tts_voice_model__model_sha256 CHECK (model_sha256 ~ '^[0-9a-f]{64}$'),
    CONSTRAINT ck_tts_voice_model__config_sha256 CHECK (config_sha256 ~ '^[0-9a-f]{64}$'),
    CONSTRAINT ck_tts_voice_model__status CHECK (status IN (
        'UPLOADING', 'UPLOADED', 'VALIDATING', 'READY_FOR_REVIEW',
        'APPROVED', 'ACTIVE', 'DEPRECATED', 'INVALID', 'QUARANTINED')),
    CONSTRAINT ck_tts_voice_model__license_name CHECK (
        license_name IS NULL OR (license_name = btrim(license_name) AND char_length(license_name) > 0)),
    CONSTRAINT ck_tts_voice_model__license_reference CHECK (
        license_reference IS NULL OR (license_reference = btrim(license_reference) AND char_length(license_reference) > 0)),
    CONSTRAINT ck_tts_voice_model__approved_at CHECK (
        (status IN ('APPROVED', 'ACTIVE', 'DEPRECATED') AND approved_at IS NOT NULL)
        OR (status NOT IN ('APPROVED', 'ACTIVE', 'DEPRECATED')))
);
CREATE INDEX ix_tts_voice_model__voice_status_code
    ON app.tts_voice_model (voice_id, status, code);
ALTER TABLE app.tts_voice
    ADD CONSTRAINT fk_tts_voice__default_model_same_voice
    FOREIGN KEY (default_model_id, id)
    REFERENCES app.tts_voice_model (id, voice_id)
    ON DELETE RESTRICT;
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback ALTER TABLE app.tts_voice DROP CONSTRAINT fk_tts_voice__default_model_same_voice;
--rollback DROP TABLE app.tts_voice_model;
--rollback RESET ROLE;

--changeset voxprep:b1-p5-0003-guard-immutable-tts-model-function splitStatements:false
SET ROLE voxprep_owner;
CREATE FUNCTION app.tts_voice_model_immutable_identity_guard()
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
       OR NEW.config_sha256 IS DISTINCT FROM OLD.config_sha256 THEN
        RAISE EXCEPTION 'TTS voice model execution identity is immutable';
    END IF;
    RETURN NEW;
END;
$$;
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP FUNCTION app.tts_voice_model_immutable_identity_guard();
--rollback RESET ROLE;

--changeset voxprep:b1-p5-0004-guard-immutable-tts-model-trigger
SET ROLE voxprep_owner;
CREATE TRIGGER trg_tts_voice_model_immutable_identity
BEFORE UPDATE ON app.tts_voice_model
FOR EACH ROW
EXECUTE FUNCTION app.tts_voice_model_immutable_identity_guard();
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TRIGGER trg_tts_voice_model_immutable_identity ON app.tts_voice_model;
--rollback RESET ROLE;
