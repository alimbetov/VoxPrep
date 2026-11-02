--liquibase formatted sql

--changeset voxprep:b1-p12-0001-add-output-finalization-identity
SET ROLE voxprep_owner;
ALTER TABLE app.tts_job
    ADD COLUMN finalized_by_worker varchar(128),
    ADD COLUMN finalized_lease_token uuid,
    ADD COLUMN finalized_at timestamptz,
    ADD CONSTRAINT ck_tts_job__finalization_identity CHECK (
        (finalized_by_worker IS NULL AND finalized_lease_token IS NULL AND finalized_at IS NULL)
        OR
        (finalized_by_worker IS NOT NULL AND finalized_lease_token IS NOT NULL AND finalized_at IS NOT NULL)),
    ADD CONSTRAINT ck_tts_job__finalized_worker CHECK (
        finalized_by_worker IS NULL OR (
            finalized_by_worker = btrim(finalized_by_worker)
            AND char_length(finalized_by_worker) > 0));
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback ALTER TABLE app.tts_job DROP CONSTRAINT ck_tts_job__finalized_worker;
--rollback ALTER TABLE app.tts_job DROP CONSTRAINT ck_tts_job__finalization_identity;
--rollback ALTER TABLE app.tts_job DROP COLUMN finalized_at;
--rollback ALTER TABLE app.tts_job DROP COLUMN finalized_lease_token;
--rollback ALTER TABLE app.tts_job DROP COLUMN finalized_by_worker;
--rollback RESET ROLE;
