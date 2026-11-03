--liquibase formatted sql

--changeset voxprep:b1-p4-0001-create-collection-content-member
SET ROLE voxprep_owner;

CREATE TABLE app.catalogue_collection_content_member (
    id uuid NOT NULL,
    version bigint NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    collection_id uuid NOT NULL,
    position integer NOT NULL,
    content_revision_id uuid NOT NULL,
    CONSTRAINT pk_catalogue_collection_content_member PRIMARY KEY (id),
    CONSTRAINT uk_catalogue_collection_content_member__position UNIQUE (collection_id, position),
    CONSTRAINT uk_catalogue_collection_content_member__revision UNIQUE (collection_id, content_revision_id),
    CONSTRAINT fk_catalogue_collection_content_member__collection FOREIGN KEY (collection_id)
        REFERENCES app.catalogue_learning_collection (id) ON DELETE RESTRICT,
    CONSTRAINT fk_catalogue_collection_content_member__revision FOREIGN KEY (content_revision_id)
        REFERENCES app.content_revision (id) ON DELETE RESTRICT,
    CONSTRAINT ck_catalogue_collection_content_member__position CHECK (position >= 0)
);

CREATE INDEX ix_catalogue_collection_content_member__collection_position
    ON app.catalogue_collection_content_member (collection_id, position);

CREATE INDEX ix_catalogue_collection_content_member__revision
    ON app.catalogue_collection_content_member (content_revision_id);

RESET ROLE;

--rollback SET ROLE voxprep_owner;
--rollback DROP TABLE app.catalogue_collection_content_member;
--rollback RESET ROLE;
