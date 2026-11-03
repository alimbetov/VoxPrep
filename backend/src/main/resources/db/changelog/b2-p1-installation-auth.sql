--liquibase formatted sql

--changeset voxprep:b2-p1-0001-create-installation
SET ROLE voxprep_owner;
CREATE TABLE app.installation (
    id uuid NOT NULL,
    version bigint NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    installation_id uuid NOT NULL,
    status varchar(32) NOT NULL,
    token_sha256 varchar(64) NOT NULL,
    token_issued_at timestamptz NOT NULL,
    CONSTRAINT pk_installation PRIMARY KEY (id),
    CONSTRAINT uk_installation__installation_id UNIQUE (installation_id),
    CONSTRAINT uk_installation__token_sha256 UNIQUE (token_sha256),
    CONSTRAINT ck_installation__status CHECK (status IN ('ACTIVE', 'BLOCKED', 'REVOKED')),
    CONSTRAINT ck_installation__token_sha256 CHECK (token_sha256 ~ '^[0-9a-f]{64}$')
);
CREATE INDEX ix_installation__status ON app.installation (status);
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TABLE app.installation;
--rollback RESET ROLE;
