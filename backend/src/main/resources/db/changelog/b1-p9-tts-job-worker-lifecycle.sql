--liquibase formatted sql

--changeset voxprep:b1-p9-0001-add-tts-job-failure-state
SET ROLE voxprep_owner;
ALTER TABLE app.tts_job
    ADD COLUMN failure_code varchar(64),
    ADD COLUMN failure_message varchar(2000),
    ADD COLUMN failed_at timestamptz,
    ADD CONSTRAINT ck_tts_job__failure_state CHECK (
        (status = 'FAILED' AND failure_code IS NOT NULL AND failed_at IS NOT NULL)
        OR (status <> 'FAILED' AND failure_code IS NULL AND failure_message IS NULL AND failed_at IS NULL)),
    ADD CONSTRAINT ck_tts_job__failure_code CHECK (
        failure_code IS NULL OR (failure_code = btrim(failure_code) AND char_length(failure_code) > 0)),
    ADD CONSTRAINT ck_tts_job__failure_message CHECK (
        failure_message IS NULL OR (failure_message = btrim(failure_message) AND char_length(failure_message) > 0));
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback ALTER TABLE app.tts_job DROP CONSTRAINT ck_tts_job__failure_message;
--rollback ALTER TABLE app.tts_job DROP CONSTRAINT ck_tts_job__failure_code;
--rollback ALTER TABLE app.tts_job DROP CONSTRAINT ck_tts_job__failure_state;
--rollback ALTER TABLE app.tts_job DROP COLUMN failed_at;
--rollback ALTER TABLE app.tts_job DROP COLUMN failure_message;
--rollback ALTER TABLE app.tts_job DROP COLUMN failure_code;
--rollback RESET ROLE;
