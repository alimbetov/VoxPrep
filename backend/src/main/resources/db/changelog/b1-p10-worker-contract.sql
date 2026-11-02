--liquibase formatted sql

--changeset voxprep:b1-p10-0001-add-worker-claim-snapshot
SET ROLE voxprep_owner;
ALTER TABLE app.tts_job
    ADD COLUMN file_id uuid,
    ADD COLUMN content_revision_id uuid,
    ADD COLUMN audio_role varchar(64),
    ADD COLUMN normalized_tts_text text,
    ADD COLUMN language varchar(64),
    ADD COLUMN fingerprint varchar(64),
    ADD CONSTRAINT uk_tts_job__file_id UNIQUE (file_id),
    ADD CONSTRAINT fk_tts_job__content_revision FOREIGN KEY (content_revision_id)
        REFERENCES app.content_revision (id) ON DELETE RESTRICT,
    ADD CONSTRAINT ck_tts_job__worker_snapshot CHECK (
        (file_id IS NULL AND content_revision_id IS NULL AND audio_role IS NULL
            AND normalized_tts_text IS NULL AND language IS NULL AND fingerprint IS NULL)
        OR
        (file_id IS NOT NULL AND content_revision_id IS NOT NULL AND audio_role IS NOT NULL
            AND normalized_tts_text IS NOT NULL AND language IS NOT NULL AND fingerprint IS NOT NULL)),
    ADD CONSTRAINT ck_tts_job__audio_role CHECK (
        audio_role IS NULL OR (audio_role = btrim(audio_role) AND char_length(audio_role) > 0)),
    ADD CONSTRAINT ck_tts_job__normalized_tts_text CHECK (
        normalized_tts_text IS NULL OR (normalized_tts_text = btrim(normalized_tts_text) AND char_length(normalized_tts_text) > 0)),
    ADD CONSTRAINT ck_tts_job__language CHECK (
        language IS NULL OR (language = btrim(language) AND char_length(language) > 0)),
    ADD CONSTRAINT ck_tts_job__fingerprint CHECK (
        fingerprint IS NULL OR fingerprint ~ '^[0-9a-f]{64}$');
CREATE INDEX ix_tts_job__worker_claimable
    ON app.tts_job (status, created_at, id)
    WHERE file_id IS NOT NULL;
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP INDEX app.ix_tts_job__worker_claimable;
--rollback ALTER TABLE app.tts_job DROP CONSTRAINT ck_tts_job__fingerprint;
--rollback ALTER TABLE app.tts_job DROP CONSTRAINT ck_tts_job__language;
--rollback ALTER TABLE app.tts_job DROP CONSTRAINT ck_tts_job__normalized_tts_text;
--rollback ALTER TABLE app.tts_job DROP CONSTRAINT ck_tts_job__audio_role;
--rollback ALTER TABLE app.tts_job DROP CONSTRAINT ck_tts_job__worker_snapshot;
--rollback ALTER TABLE app.tts_job DROP CONSTRAINT fk_tts_job__content_revision;
--rollback ALTER TABLE app.tts_job DROP CONSTRAINT uk_tts_job__file_id;
--rollback ALTER TABLE app.tts_job DROP COLUMN fingerprint;
--rollback ALTER TABLE app.tts_job DROP COLUMN language;
--rollback ALTER TABLE app.tts_job DROP COLUMN normalized_tts_text;
--rollback ALTER TABLE app.tts_job DROP COLUMN audio_role;
--rollback ALTER TABLE app.tts_job DROP COLUMN content_revision_id;
--rollback ALTER TABLE app.tts_job DROP COLUMN file_id;
--rollback RESET ROLE;

--changeset voxprep:b1-p10-0002-guard-worker-claim-snapshot-function splitStatements:false
SET ROLE voxprep_owner;
CREATE FUNCTION app.tts_job_worker_snapshot_guard()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.file_id IS NOT NULL AND (
        NEW.file_id IS DISTINCT FROM OLD.file_id
        OR NEW.content_revision_id IS DISTINCT FROM OLD.content_revision_id
        OR NEW.audio_role IS DISTINCT FROM OLD.audio_role
        OR NEW.normalized_tts_text IS DISTINCT FROM OLD.normalized_tts_text
        OR NEW.language IS DISTINCT FROM OLD.language
        OR NEW.fingerprint IS DISTINCT FROM OLD.fingerprint) THEN
        RAISE EXCEPTION 'TTS worker claim snapshot is immutable once assigned'
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP FUNCTION app.tts_job_worker_snapshot_guard();
--rollback RESET ROLE;

--changeset voxprep:b1-p10-0003-guard-worker-claim-snapshot-trigger
SET ROLE voxprep_owner;
CREATE TRIGGER trg_tts_job_worker_snapshot
BEFORE UPDATE OF file_id, content_revision_id, audio_role, normalized_tts_text, language, fingerprint
ON app.tts_job
FOR EACH ROW
EXECUTE FUNCTION app.tts_job_worker_snapshot_guard();
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TRIGGER trg_tts_job_worker_snapshot ON app.tts_job;
--rollback RESET ROLE;
