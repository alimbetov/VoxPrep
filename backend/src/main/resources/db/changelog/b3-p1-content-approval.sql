--liquibase formatted sql

--changeset voxprep:b3-p1-0001-content-approval-lifecycle splitStatements:false
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

CREATE OR REPLACE FUNCTION app.content_revision_mutation_guard()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'Content revisions are append-only and cannot be hard deleted'
            USING ERRCODE = '23514';
    END IF;

    IF NEW.content_code IS DISTINCT FROM OLD.content_code
       OR NEW.content_type IS DISTINCT FROM OLD.content_type
       OR NEW.revision_number IS DISTINCT FROM OLD.revision_number THEN
        RAISE EXCEPTION 'Content revision exact identity is immutable'
            USING ERRCODE = '23514';
    END IF;

    IF OLD.lifecycle <> 'DRAFT' AND (
        NEW.checksum_sha256 IS DISTINCT FROM OLD.checksum_sha256
        OR NEW.title IS DISTINCT FROM OLD.title
        OR NEW.subtitle IS DISTINCT FROM OLD.subtitle
        OR NEW.description IS DISTINCT FROM OLD.description
        OR NEW.category_code IS DISTINCT FROM OLD.category_code
        OR NEW.level_code IS DISTINCT FROM OLD.level_code
        OR NEW.minutes IS DISTINCT FROM OLD.minutes) THEN
        RAISE EXCEPTION 'Frozen content revision payload is immutable after DRAFT'
            USING ERRCODE = '23514';
    END IF;

    IF OLD.approved_at IS NOT NULL AND NEW.approved_at IS DISTINCT FROM OLD.approved_at THEN
        RAISE EXCEPTION 'approved_at is immutable once assigned'
            USING ERRCODE = '23514';
    END IF;

    IF OLD.published_at IS NOT NULL AND NEW.published_at IS DISTINCT FROM OLD.published_at THEN
        RAISE EXCEPTION 'published_at is immutable once assigned'
            USING ERRCODE = '23514';
    END IF;

    IF NEW.lifecycle IS DISTINCT FROM OLD.lifecycle THEN
        IF NOT (
            (OLD.lifecycle = 'DRAFT' AND NEW.lifecycle = 'READY_FOR_AUDIO')
            OR (OLD.lifecycle = 'READY_FOR_AUDIO' AND NEW.lifecycle = 'READY_FOR_REVIEW')
            OR (OLD.lifecycle = 'READY_FOR_REVIEW' AND NEW.lifecycle = 'APPROVED')
            OR (OLD.lifecycle = 'APPROVED' AND NEW.lifecycle = 'PUBLISHED')
            OR (OLD.lifecycle = 'PUBLISHED' AND NEW.lifecycle = 'ARCHIVED')) THEN
            RAISE EXCEPTION 'Invalid content lifecycle transition: % -> %', OLD.lifecycle, NEW.lifecycle
                USING ERRCODE = '23514';
        END IF;
    END IF;

    IF OLD.lifecycle = 'DRAFT' AND NEW.lifecycle = 'READY_FOR_AUDIO' THEN
        PERFORM app.assert_content_revision_body_complete(NEW.id, NEW.content_type);
    END IF;

    RETURN NEW;
END;
$$;

RESET ROLE;

--rollback SET ROLE voxprep_owner;
--rollback CREATE OR REPLACE FUNCTION app.content_revision_mutation_guard() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN IF TG_OP = 'DELETE' THEN RAISE EXCEPTION 'Content revisions are append-only and cannot be hard deleted' USING ERRCODE = '23514'; END IF; IF NEW.content_code IS DISTINCT FROM OLD.content_code OR NEW.content_type IS DISTINCT FROM OLD.content_type OR NEW.revision_number IS DISTINCT FROM OLD.revision_number THEN RAISE EXCEPTION 'Content revision exact identity is immutable' USING ERRCODE = '23514'; END IF; IF OLD.lifecycle <> 'DRAFT' AND (NEW.checksum_sha256 IS DISTINCT FROM OLD.checksum_sha256 OR NEW.title IS DISTINCT FROM OLD.title OR NEW.subtitle IS DISTINCT FROM OLD.subtitle OR NEW.description IS DISTINCT FROM OLD.description OR NEW.category_code IS DISTINCT FROM OLD.category_code OR NEW.level_code IS DISTINCT FROM OLD.level_code OR NEW.minutes IS DISTINCT FROM OLD.minutes) THEN RAISE EXCEPTION 'Frozen content revision payload is immutable after DRAFT' USING ERRCODE = '23514'; END IF; IF OLD.published_at IS NOT NULL AND NEW.published_at IS DISTINCT FROM OLD.published_at THEN RAISE EXCEPTION 'published_at is immutable once assigned' USING ERRCODE = '23514'; END IF; IF NEW.lifecycle IS DISTINCT FROM OLD.lifecycle THEN IF NOT ((OLD.lifecycle = 'DRAFT' AND NEW.lifecycle = 'READY_FOR_AUDIO') OR (OLD.lifecycle = 'READY_FOR_AUDIO' AND NEW.lifecycle = 'READY_FOR_REVIEW') OR (OLD.lifecycle = 'READY_FOR_REVIEW' AND NEW.lifecycle = 'PUBLISHED') OR (OLD.lifecycle = 'PUBLISHED' AND NEW.lifecycle = 'ARCHIVED')) THEN RAISE EXCEPTION 'Invalid content lifecycle transition: % -> %', OLD.lifecycle, NEW.lifecycle USING ERRCODE = '23514'; END IF; END IF; IF OLD.lifecycle = 'DRAFT' AND NEW.lifecycle = 'READY_FOR_AUDIO' THEN PERFORM app.assert_content_revision_body_complete(NEW.id, NEW.content_type); END IF; RETURN NEW; END; $$;
--rollback ALTER TABLE app.content_revision DROP CONSTRAINT ck_content_revision__approved_at;
--rollback ALTER TABLE app.content_revision DROP COLUMN approved_at;
--rollback ALTER TABLE app.content_revision DROP CONSTRAINT ck_content_revision__lifecycle;
--rollback ALTER TABLE app.content_revision ADD CONSTRAINT ck_content_revision__lifecycle CHECK (lifecycle IN ('DRAFT', 'READY_FOR_AUDIO', 'READY_FOR_REVIEW', 'PUBLISHED', 'ARCHIVED'));
--rollback RESET ROLE;
