--liquibase formatted sql

--changeset voxprep:api-r2-0001-wire-publication-document
SET ROLE voxprep_owner;
CREATE TABLE app.publication_wire_document (
    id uuid NOT NULL,
    version bigint NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    release_id uuid NOT NULL,
    document_kind varchar(16) NOT NULL,
    resource_code varchar(128) NOT NULL,
    variant varchar(64) NOT NULL,
    revision bigint NOT NULL,
    checksum_sha256 varchar(64) NOT NULL,
    body_json text NOT NULL,
    CONSTRAINT pk_publication_wire_document PRIMARY KEY (id),
    CONSTRAINT fk_publication_wire_document__release
        FOREIGN KEY (release_id) REFERENCES app.publication_release(id) ON DELETE RESTRICT,
    CONSTRAINT uk_publication_wire_document__identity
        UNIQUE (release_id, document_kind, resource_code, variant, revision),
    CONSTRAINT ck_publication_wire_document__kind
        CHECK (document_kind IN ('ROOT', 'PACK', 'CATALOGUE')),
    CONSTRAINT ck_publication_wire_document__revision CHECK (revision > 0),
    CONSTRAINT ck_publication_wire_document__checksum
        CHECK (checksum_sha256 ~ '^[0-9a-f]{64}$'),
    CONSTRAINT ck_publication_wire_document__size
        CHECK (octet_length(body_json) BETWEEN 2 AND 16777216)
);
CREATE INDEX ix_publication_wire_document__release
    ON app.publication_wire_document (release_id, document_kind);
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TABLE app.publication_wire_document;
--rollback RESET ROLE;

--changeset voxprep:api-r2-0002-wire-document-immutable-guard splitStatements:false
SET ROLE voxprep_owner;
CREATE FUNCTION app.publication_wire_document_immutable_guard()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        RAISE EXCEPTION 'published wire documents are immutable'
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_publication_wire_document_immutable
BEFORE UPDATE OR DELETE ON app.publication_wire_document
FOR EACH ROW EXECUTE FUNCTION app.publication_wire_document_immutable_guard();
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TRIGGER trg_publication_wire_document_immutable ON app.publication_wire_document;
--rollback DROP FUNCTION app.publication_wire_document_immutable_guard();
--rollback RESET ROLE;
