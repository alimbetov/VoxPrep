--liquibase formatted sql

--changeset voxprep:b3-p4-0001-content-localization-authoring splitStatements:false
SET ROLE voxprep_owner;

CREATE TABLE app.content_localization_revision (
    id uuid NOT NULL,
    version bigint NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    content_revision_id uuid NOT NULL,
    locale varchar(64) NOT NULL,
    localization_revision_number integer NOT NULL,
    lifecycle varchar(32) NOT NULL,
    checksum_sha256 varchar(64) NOT NULL,
    title varchar(256),
    subtitle varchar(512),
    description varchar(4096),
    translation text,
    hint text,
    explanation text,
    approved_at timestamptz,
    CONSTRAINT pk_content_localization_revision PRIMARY KEY (id),
    CONSTRAINT uk_content_localization_revision__identity UNIQUE (
        content_revision_id, locale, localization_revision_number),
    CONSTRAINT fk_content_localization_revision__content FOREIGN KEY (content_revision_id)
        REFERENCES app.content_revision(id) ON DELETE RESTRICT,
    CONSTRAINT ck_content_localization_revision__locale CHECK (
        locale ~ '^[A-Za-z0-9]+(-[A-Za-z0-9]+)*$'),
    CONSTRAINT ck_content_localization_revision__revision CHECK (localization_revision_number >= 1),
    CONSTRAINT ck_content_localization_revision__lifecycle CHECK (
        lifecycle IN ('DRAFT', 'READY_FOR_REVIEW', 'APPROVED')),
    CONSTRAINT ck_content_localization_revision__checksum CHECK (checksum_sha256 ~ '^[0-9a-f]{64}$'),
    CONSTRAINT ck_content_localization_revision__payload CHECK (
        title IS NOT NULL OR subtitle IS NOT NULL OR description IS NOT NULL
        OR translation IS NOT NULL OR hint IS NOT NULL OR explanation IS NOT NULL),
    CONSTRAINT ck_content_localization_revision__approved_at CHECK (
        (lifecycle = 'APPROVED' AND approved_at IS NOT NULL)
        OR (lifecycle <> 'APPROVED' AND approved_at IS NULL))
);

CREATE INDEX ix_content_localization_revision__content_locale
    ON app.content_localization_revision(content_revision_id, locale, localization_revision_number);

CREATE TABLE app.content_localization_review_audit (
    id uuid NOT NULL,
    localization_revision_id uuid NOT NULL,
    action varchar(32) NOT NULL,
    actor varchar(128) NOT NULL,
    reason varchar(512),
    comment varchar(2048),
    occurred_at timestamptz NOT NULL,
    CONSTRAINT pk_content_localization_review_audit PRIMARY KEY (id),
    CONSTRAINT fk_content_localization_review_audit__revision FOREIGN KEY (localization_revision_id)
        REFERENCES app.content_localization_revision(id) ON DELETE RESTRICT,
    CONSTRAINT ck_content_localization_review_audit__action CHECK (
        action IN ('SUBMITTED_FOR_REVIEW', 'APPROVED')),
    CONSTRAINT ck_content_localization_review_audit__actor CHECK (char_length(btrim(actor)) > 0)
);

CREATE INDEX ix_content_localization_review_audit__revision_time
    ON app.content_localization_review_audit(localization_revision_id, occurred_at, id);

CREATE FUNCTION app.content_localization_next_number_guard()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    expected_revision integer;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtextextended(NEW.content_revision_id::text || '|' || NEW.locale, 0));

    SELECT COALESCE(MAX(localization_revision_number), 0) + 1
      INTO expected_revision
      FROM app.content_localization_revision
     WHERE content_revision_id = NEW.content_revision_id
       AND locale = NEW.locale;

    IF NEW.localization_revision_number <> expected_revision THEN
        RAISE EXCEPTION 'Localization revision must be %, got %', expected_revision, NEW.localization_revision_number
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

CREATE FUNCTION app.content_localization_mutation_guard()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'Content localization revisions are append-only'
            USING ERRCODE = '23514';
    END IF;

    IF NEW.content_revision_id IS DISTINCT FROM OLD.content_revision_id
       OR NEW.locale IS DISTINCT FROM OLD.locale
       OR NEW.localization_revision_number IS DISTINCT FROM OLD.localization_revision_number THEN
        RAISE EXCEPTION 'Localization exact identity is immutable'
            USING ERRCODE = '23514';
    END IF;

    IF OLD.lifecycle <> 'DRAFT' AND (
        NEW.checksum_sha256 IS DISTINCT FROM OLD.checksum_sha256
        OR NEW.title IS DISTINCT FROM OLD.title
        OR NEW.subtitle IS DISTINCT FROM OLD.subtitle
        OR NEW.description IS DISTINCT FROM OLD.description
        OR NEW.translation IS DISTINCT FROM OLD.translation
        OR NEW.hint IS DISTINCT FROM OLD.hint
        OR NEW.explanation IS DISTINCT FROM OLD.explanation) THEN
        RAISE EXCEPTION 'Frozen localization payload is immutable after DRAFT'
            USING ERRCODE = '23514';
    END IF;

    IF OLD.approved_at IS NOT NULL AND NEW.approved_at IS DISTINCT FROM OLD.approved_at THEN
        RAISE EXCEPTION 'Localization approved_at is immutable once assigned'
            USING ERRCODE = '23514';
    END IF;

    IF NEW.lifecycle IS DISTINCT FROM OLD.lifecycle AND NOT (
        (OLD.lifecycle = 'DRAFT' AND NEW.lifecycle = 'READY_FOR_REVIEW')
        OR (OLD.lifecycle = 'READY_FOR_REVIEW' AND NEW.lifecycle = 'APPROVED')) THEN
        RAISE EXCEPTION 'Invalid localization lifecycle transition: % -> %', OLD.lifecycle, NEW.lifecycle
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

CREATE FUNCTION app.content_localization_audit_immutable_guard()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'Content localization review audit is append-only'
        USING ERRCODE = '23514';
END;
$$;

CREATE TRIGGER trg_content_localization_revision__next_number
BEFORE INSERT ON app.content_localization_revision
FOR EACH ROW EXECUTE FUNCTION app.content_localization_next_number_guard();

CREATE TRIGGER trg_content_localization_revision__mutation
BEFORE UPDATE OR DELETE ON app.content_localization_revision
FOR EACH ROW EXECUTE FUNCTION app.content_localization_mutation_guard();

CREATE TRIGGER trg_content_localization_review_audit__immutable
BEFORE UPDATE OR DELETE ON app.content_localization_review_audit
FOR EACH ROW EXECUTE FUNCTION app.content_localization_audit_immutable_guard();

RESET ROLE;

--rollback SET ROLE voxprep_owner;
--rollback DROP TRIGGER IF EXISTS trg_content_localization_review_audit__immutable ON app.content_localization_review_audit;
--rollback DROP TRIGGER IF EXISTS trg_content_localization_revision__mutation ON app.content_localization_revision;
--rollback DROP TRIGGER IF EXISTS trg_content_localization_revision__next_number ON app.content_localization_revision;
--rollback DROP FUNCTION IF EXISTS app.content_localization_audit_immutable_guard();
--rollback DROP FUNCTION IF EXISTS app.content_localization_mutation_guard();
--rollback DROP FUNCTION IF EXISTS app.content_localization_next_number_guard();
--rollback DROP TABLE IF EXISTS app.content_localization_review_audit;
--rollback DROP TABLE IF EXISTS app.content_localization_revision;
--rollback RESET ROLE;
