--liquibase formatted sql

--changeset voxprep:b6-p2-0001-publication-candidate-manifest
SET ROLE voxprep_owner;
CREATE TABLE app.publication_candidate_manifest_ref (
    id uuid NOT NULL,
    version bigint NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    candidate_id uuid NOT NULL,
    position integer NOT NULL,
    content_code varchar(128) NOT NULL,
    content_type varchar(32) NOT NULL,
    revision_number integer NOT NULL,
    checksum_sha256 varchar(64) NOT NULL,
    CONSTRAINT pk_publication_candidate_manifest_ref PRIMARY KEY (id),
    CONSTRAINT fk_pub_candidate_manifest__candidate FOREIGN KEY (candidate_id)
        REFERENCES app.publication_candidate (id) ON DELETE RESTRICT,
    CONSTRAINT uk_pub_candidate_manifest__position UNIQUE (candidate_id, position),
    CONSTRAINT uk_pub_candidate_manifest__identity UNIQUE (
        candidate_id, content_code, content_type, revision_number),
    CONSTRAINT ck_pub_candidate_manifest__position CHECK (position >= 0),
    CONSTRAINT ck_pub_candidate_manifest__revision CHECK (revision_number > 0),
    CONSTRAINT ck_pub_candidate_manifest__checksum CHECK (checksum_sha256 ~ '^[0-9a-f]{64}$'),
    CONSTRAINT ck_pub_candidate_manifest__content_type CHECK (
        content_type IN ('vocabulary', 'interview', 'topic', 'phrase', 'shadowing', 'question', 'practice_test'))
);
CREATE INDEX ix_pub_candidate_manifest__candidate
    ON app.publication_candidate_manifest_ref (candidate_id, position);
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TABLE app.publication_candidate_manifest_ref;
--rollback RESET ROLE;

--changeset voxprep:b6-p2-0002-publication-candidate-manifest-guard splitStatements:false
SET ROLE voxprep_owner;
CREATE FUNCTION app.publication_candidate_manifest_guard()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    candidate_status varchar(32);
BEGIN
    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        RAISE EXCEPTION 'publication candidate manifest refs are immutable'
            USING ERRCODE = '23514';
    END IF;

    SELECT status
      INTO candidate_status
      FROM app.publication_candidate
     WHERE id = NEW.candidate_id
     FOR SHARE;

    IF candidate_status IS NULL THEN
        RAISE EXCEPTION 'publication candidate does not exist: %', NEW.candidate_id
            USING ERRCODE = '23503';
    END IF;

    IF candidate_status <> 'DRAFT' THEN
        RAISE EXCEPTION 'manifest refs may only be inserted for a DRAFT candidate'
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_publication_candidate_manifest_guard
BEFORE INSERT OR UPDATE OR DELETE ON app.publication_candidate_manifest_ref
FOR EACH ROW
EXECUTE FUNCTION app.publication_candidate_manifest_guard();
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TRIGGER trg_publication_candidate_manifest_guard ON app.publication_candidate_manifest_ref;
--rollback DROP FUNCTION app.publication_candidate_manifest_guard();
--rollback RESET ROLE;
