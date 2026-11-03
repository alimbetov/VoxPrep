--liquibase formatted sql

--changeset voxprep:b7-r4-0001-content-asset-binding
SET ROLE voxprep_owner;
CREATE TABLE app.content_asset_binding (
    id uuid PRIMARY KEY,
    version bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    content_revision_id uuid NOT NULL,
    role varchar(32) NOT NULL,
    file_asset_id uuid NOT NULL,
    source_fingerprint varchar(64),
    CONSTRAINT fk_content_asset_binding__revision
        FOREIGN KEY (content_revision_id) REFERENCES app.content_revision(id) ON DELETE RESTRICT,
    CONSTRAINT fk_content_asset_binding__asset
        FOREIGN KEY (file_asset_id) REFERENCES app.file_asset(id) ON DELETE RESTRICT,
    CONSTRAINT uk_content_asset_binding__revision_role
        UNIQUE (content_revision_id, role),
    CONSTRAINT ck_content_asset_binding__role
        CHECK (role IN ('COVER_IMAGE','CONTENT_IMAGE','PRONUNCIATION','QUESTION','SAMPLE_ANSWER','NARRATION','SHADOWING')),
    CONSTRAINT ck_content_asset_binding__fingerprint
        CHECK (source_fingerprint IS NULL OR source_fingerprint ~ '^[0-9a-f]{64}$')
);
CREATE INDEX ix_content_asset_binding__asset ON app.content_asset_binding(file_asset_id);
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TABLE app.content_asset_binding;
--rollback RESET ROLE;

--changeset voxprep:b7-r4-0002-bind-ready-tts-output splitStatements:false
SET ROLE voxprep_owner;
CREATE FUNCTION app.bind_ready_tts_output_to_content()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    binding_role varchar(32);
BEGIN
    IF NEW.status <> 'READY'
       OR NEW.output_asset_id IS NULL
       OR NEW.content_revision_id IS NULL
       OR NEW.audio_role IS NULL
       OR NEW.fingerprint IS NULL THEN
        RETURN NEW;
    END IF;

    binding_role := CASE NEW.audio_role
        WHEN 'pronunciation' THEN 'PRONUNCIATION'
        WHEN 'question' THEN 'QUESTION'
        WHEN 'sampleAnswer' THEN 'SAMPLE_ANSWER'
        WHEN 'narration' THEN 'NARRATION'
        WHEN 'shadowing' THEN 'SHADOWING'
        ELSE NULL
    END;

    IF binding_role IS NULL THEN
        RAISE EXCEPTION 'Unsupported finalized TTS audio role: %', NEW.audio_role
            USING ERRCODE = '23514';
    END IF;

    INSERT INTO app.content_asset_binding (
        id, version, created_at, updated_at,
        content_revision_id, role, file_asset_id, source_fingerprint)
    VALUES (
        gen_random_uuid(), 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
        NEW.content_revision_id, binding_role, NEW.output_asset_id, NEW.fingerprint)
    ON CONFLICT (content_revision_id, role)
    DO UPDATE SET
        file_asset_id = EXCLUDED.file_asset_id,
        source_fingerprint = EXCLUDED.source_fingerprint,
        version = app.content_asset_binding.version + 1,
        updated_at = CURRENT_TIMESTAMP;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_tts_job_bind_ready_output
AFTER UPDATE OF status, output_asset_id ON app.tts_job
FOR EACH ROW
WHEN (NEW.status = 'READY' AND NEW.output_asset_id IS NOT NULL)
EXECUTE FUNCTION app.bind_ready_tts_output_to_content();
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TRIGGER trg_tts_job_bind_ready_output ON app.tts_job;
--rollback DROP FUNCTION app.bind_ready_tts_output_to_content();
--rollback RESET ROLE;
