--liquibase formatted sql

--changeset voxprep:b3-p2-0001-content-review-audit splitStatements:false
SET ROLE voxprep_owner;

CREATE TABLE app.content_review_audit (
    id uuid NOT NULL,
    content_revision_id uuid NOT NULL,
    action varchar(32) NOT NULL,
    actor varchar(128) NOT NULL,
    reason varchar(512),
    comment varchar(2048),
    occurred_at timestamptz NOT NULL,
    CONSTRAINT pk_content_review_audit PRIMARY KEY (id),
    CONSTRAINT fk_content_review_audit__revision FOREIGN KEY (content_revision_id)
        REFERENCES app.content_revision(id) ON DELETE RESTRICT,
    CONSTRAINT ck_content_review_audit__action CHECK (action IN ('SUBMITTED_FOR_REVIEW', 'APPROVED')),
    CONSTRAINT ck_content_review_audit__actor CHECK (char_length(btrim(actor)) > 0),
    CONSTRAINT ck_content_review_audit__reason CHECK (reason IS NULL OR char_length(btrim(reason)) > 0),
    CONSTRAINT ck_content_review_audit__comment CHECK (comment IS NULL OR char_length(btrim(comment)) > 0)
);

CREATE INDEX ix_content_review_audit__revision_time
    ON app.content_review_audit(content_revision_id, occurred_at, id);

CREATE FUNCTION app.content_review_audit_immutable_guard()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'Content review audit is append-only'
        USING ERRCODE = '23514';
END;
$$;

CREATE TRIGGER trg_content_review_audit__immutable
BEFORE UPDATE OR DELETE ON app.content_review_audit
FOR EACH ROW EXECUTE FUNCTION app.content_review_audit_immutable_guard();

RESET ROLE;

--rollback SET ROLE voxprep_owner;
--rollback DROP TRIGGER IF EXISTS trg_content_review_audit__immutable ON app.content_review_audit;
--rollback DROP FUNCTION IF EXISTS app.content_review_audit_immutable_guard();
--rollback DROP TABLE IF EXISTS app.content_review_audit;
--rollback RESET ROLE;
