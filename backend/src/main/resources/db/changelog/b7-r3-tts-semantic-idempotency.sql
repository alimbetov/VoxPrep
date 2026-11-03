--liquibase formatted sql

--changeset voxprep:b7-r3-0001-unique-tts-semantic-fingerprint
SET ROLE voxprep_owner;
CREATE UNIQUE INDEX uk_tts_job__fingerprint
    ON app.tts_job (fingerprint)
    WHERE fingerprint IS NOT NULL;
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP INDEX app.uk_tts_job__fingerprint;
--rollback RESET ROLE;
