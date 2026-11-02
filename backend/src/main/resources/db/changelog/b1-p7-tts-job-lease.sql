--liquibase formatted sql

--changeset voxprep:b1-p7-0001-add-tts-job-lease
SET ROLE voxprep_owner;
ALTER TABLE app.tts_job
    ADD COLUMN attempt_count integer NOT NULL DEFAULT 0,
    ADD COLUMN lease_owner varchar(128),
    ADD COLUMN lease_token uuid,
    ADD COLUMN lease_until timestamptz,
    ADD COLUMN claimed_at timestamptz,
    ADD CONSTRAINT ck_tts_job__attempt_count CHECK (attempt_count >= 0),
    ADD CONSTRAINT ck_tts_job__lease_state CHECK (
        (status IN ('CLAIMED', 'PROCESSING')
            AND lease_owner IS NOT NULL
            AND lease_token IS NOT NULL
            AND lease_until IS NOT NULL)
        OR (status NOT IN ('CLAIMED', 'PROCESSING')
            AND lease_owner IS NULL
            AND lease_token IS NULL
            AND lease_until IS NULL)),
    ADD CONSTRAINT ck_tts_job__lease_owner CHECK (
        lease_owner IS NULL OR (lease_owner = btrim(lease_owner) AND char_length(lease_owner) > 0));
CREATE INDEX ix_tts_job__claimable
    ON app.tts_job (status, lease_until, created_at, id);
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP INDEX app.ix_tts_job__claimable;
--rollback ALTER TABLE app.tts_job DROP CONSTRAINT ck_tts_job__lease_owner;
--rollback ALTER TABLE app.tts_job DROP CONSTRAINT ck_tts_job__lease_state;
--rollback ALTER TABLE app.tts_job DROP CONSTRAINT ck_tts_job__attempt_count;
--rollback ALTER TABLE app.tts_job DROP COLUMN claimed_at;
--rollback ALTER TABLE app.tts_job DROP COLUMN lease_until;
--rollback ALTER TABLE app.tts_job DROP COLUMN lease_token;
--rollback ALTER TABLE app.tts_job DROP COLUMN lease_owner;
--rollback ALTER TABLE app.tts_job DROP COLUMN attempt_count;
--rollback RESET ROLE;
