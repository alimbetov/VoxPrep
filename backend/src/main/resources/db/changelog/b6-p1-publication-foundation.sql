--liquibase formatted sql

--changeset voxprep:b6-p1-0001-publication-sequence
SET ROLE voxprep_owner;
CREATE SEQUENCE app.publication_content_version_seq
    AS bigint
    START WITH 1
    INCREMENT BY 1
    NO CYCLE;
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP SEQUENCE app.publication_content_version_seq;
--rollback RESET ROLE;

--changeset voxprep:b6-p1-0002-publication-candidate
SET ROLE voxprep_owner;
CREATE TABLE app.publication_candidate (
    id uuid NOT NULL,
    version bigint NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    status varchar(32) NOT NULL,
    root_sha256 varchar(64),
    validated_at timestamptz,
    CONSTRAINT pk_publication_candidate PRIMARY KEY (id),
    CONSTRAINT ck_publication_candidate__status CHECK (status IN ('DRAFT', 'VALIDATED', 'REJECTED', 'PUBLISHED')),
    CONSTRAINT ck_publication_candidate__root_sha256 CHECK (root_sha256 IS NULL OR root_sha256 ~ '^[0-9a-f]{64}$'),
    CONSTRAINT ck_publication_candidate__validation CHECK (
        (status = 'DRAFT' AND root_sha256 IS NULL AND validated_at IS NULL)
        OR (status IN ('VALIDATED', 'PUBLISHED') AND root_sha256 IS NOT NULL AND validated_at IS NOT NULL)
        OR (status = 'REJECTED')
    )
);
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TABLE app.publication_candidate;
--rollback RESET ROLE;

--changeset voxprep:b6-p1-0003-publication-release
SET ROLE voxprep_owner;
CREATE TABLE app.publication_release (
    id uuid NOT NULL,
    version bigint NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    candidate_id uuid NOT NULL,
    content_version bigint NOT NULL DEFAULT nextval('app.publication_content_version_seq'),
    root_sha256 varchar(64) NOT NULL,
    published_at timestamptz NOT NULL,
    CONSTRAINT pk_publication_release PRIMARY KEY (id),
    CONSTRAINT uk_publication_release__candidate UNIQUE (candidate_id),
    CONSTRAINT uk_publication_release__content_version UNIQUE (content_version),
    CONSTRAINT fk_publication_release__candidate FOREIGN KEY (candidate_id)
        REFERENCES app.publication_candidate (id) ON DELETE RESTRICT,
    CONSTRAINT ck_publication_release__content_version CHECK (content_version > 0),
    CONSTRAINT ck_publication_release__root_sha256 CHECK (root_sha256 ~ '^[0-9a-f]{64}$')
);
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TABLE app.publication_release;
--rollback RESET ROLE;

--changeset voxprep:b6-p1-0004-publication-current
SET ROLE voxprep_owner;
CREATE TABLE app.publication_current (
    singleton_id smallint NOT NULL,
    version bigint NOT NULL,
    release_id uuid,
    updated_at timestamptz NOT NULL,
    CONSTRAINT pk_publication_current PRIMARY KEY (singleton_id),
    CONSTRAINT ck_publication_current__singleton CHECK (singleton_id = 1),
    CONSTRAINT fk_publication_current__release FOREIGN KEY (release_id)
        REFERENCES app.publication_release (id) ON DELETE RESTRICT
);
INSERT INTO app.publication_current (singleton_id, version, release_id, updated_at)
VALUES (1, 0, NULL, CURRENT_TIMESTAMP);
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DELETE FROM app.publication_current WHERE singleton_id = 1;
--rollback DROP TABLE app.publication_current;
--rollback RESET ROLE;

--changeset voxprep:b6-p1-0005-immutable-publication-release splitStatements:false
SET ROLE voxprep_owner;
CREATE FUNCTION app.publication_release_immutable_guard()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'published release is immutable'
        USING ERRCODE = '23514';
END;
$$;
CREATE TRIGGER trg_publication_release_immutable
BEFORE UPDATE OR DELETE ON app.publication_release
FOR EACH ROW
EXECUTE FUNCTION app.publication_release_immutable_guard();
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TRIGGER trg_publication_release_immutable ON app.publication_release;
--rollback DROP FUNCTION app.publication_release_immutable_guard();
--rollback RESET ROLE;
