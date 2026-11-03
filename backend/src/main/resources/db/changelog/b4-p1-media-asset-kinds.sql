--liquibase formatted sql

--changeset voxprep:b4-p1-0001-extend-file-asset-media-kinds
SET ROLE voxprep_owner;
ALTER TABLE app.file_asset
    DROP CONSTRAINT ck_file_asset__kind;
ALTER TABLE app.file_asset
    ADD CONSTRAINT ck_file_asset__kind
    CHECK (kind IN ('TTS_MODEL', 'TTS_CONFIG', 'TTS_AUDIO', 'COVER_IMAGE', 'CONTENT_IMAGE'));
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback ALTER TABLE app.file_asset DROP CONSTRAINT ck_file_asset__kind;
--rollback ALTER TABLE app.file_asset ADD CONSTRAINT ck_file_asset__kind CHECK (kind IN ('TTS_MODEL', 'TTS_CONFIG', 'TTS_AUDIO'));
--rollback RESET ROLE;
