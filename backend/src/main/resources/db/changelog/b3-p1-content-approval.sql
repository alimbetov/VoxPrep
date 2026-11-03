--liquibase formatted sql

--changeset voxprep:b3-p1-0001-content-approval-lifecycle
SET ROLE voxprep_owner;

ALTER TABLE app.content_revision
    ADD COLUMN approved_at timestamptz;

ALTER TABLE app.content_revision
    DROP CONSTRAINT ck_content_revision__lifecycle;

ALTER TABLE app.content_revision
    ADD CONSTRAINT ck_content_revision__lifecycle
    CHECK (lifecycle IN ('DRAFT', 'READY_FOR_AUDIO', 'READY_FOR_REVIEW', 'APPROVED', 'PUBLISHED', 'ARCHIVED'));

ALTER TABLE app.content_revision
    ADD CONSTRAINT ck_content_revision__approved_at CHECK (
        (lifecycle IN ('APPROVED', 'PUBLISHED', 'ARCHIVED') AND approved_at IS NOT NULL)
        OR (lifecycle NOT IN ('APPROVED', 'PUBLISHED', 'ARCHIVED') AND approved_at IS NULL));

RESET ROLE;

--rollback SET ROLE voxprep_owner;
--rollback ALTER TABLE app.content_revision DROP CONSTRAINT ck_content_revision__approved_at;
--rollback ALTER TABLE app.content_revision DROP COLUMN approved_at;
--rollback ALTER TABLE app.content_revision DROP CONSTRAINT ck_content_revision__lifecycle;
--rollback ALTER TABLE app.content_revision ADD CONSTRAINT ck_content_revision__lifecycle CHECK (lifecycle IN ('DRAFT', 'READY_FOR_AUDIO', 'READY_FOR_REVIEW', 'PUBLISHED', 'ARCHIVED'));
--rollback RESET ROLE;
