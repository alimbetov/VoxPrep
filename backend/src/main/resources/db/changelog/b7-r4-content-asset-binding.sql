--liquibase formatted sql

--changeset voxprep:b7-r4-0001-content-asset-binding
SET ROLE voxprep_owner;
CREATE TABLE app.content_asset_binding (
    id uuid PRIMARY KEY,
    version bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    content_revision_id uuid NOT NULL,
    role varchar(32) NOT NULL,
    file_asset_id uuid NOT NULL,
    source_fingerprint varchar(64),
    CONSTRAINT fk_content_asset_binding__revision
        FOREIGN KEY (content_revision_id) REFERENCES app.content_revision(id) ON DELETE RESTRICT,
    CONSTRAINT fk_content_asset_binding__asset
        FOREIGN KEY (file_asset_id) REFERENCES app.file_asset(id) ON DELETE RESTRICT,
    CONSTRAINT uk_content_asset_binding__revision_role
        UNIQUE (content_revision_id, role),
    CONSTRAINT ck_content_asset_binding__role
        CHECK (role IN ('COVER_IMAGE','CONTENT_IMAGE','PRONUNCIATION','QUESTION','SAMPLE_ANSWER','NARRATION','SHADOWING')),
    CONSTRAINT ck_content_asset_binding__fingerprint
        CHECK (source_fingerprint IS NULL OR source_fingerprint ~ '^[0-9a-f]{64}$')
);
CREATE INDEX ix_content_asset_binding__asset ON app.content_asset_binding(file_asset_id);
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TABLE app.content_asset_binding;
--rollback RESET ROLE;
