--liquibase formatted sql

--changeset voxprep:b1-p2-0001-create-vertical
SET ROLE voxprep_owner;
CREATE TABLE app.catalogue_vertical (
    id uuid NOT NULL,
    version bigint NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    code varchar(128) NOT NULL,
    section_code varchar(128) NOT NULL,
    title varchar(256) NOT NULL,
    description varchar(4096) NOT NULL,
    icon_asset_id varchar(256) NOT NULL,
    sort_order integer NOT NULL,
    availability varchar(16) NOT NULL,
    CONSTRAINT pk_catalogue_vertical PRIMARY KEY (id),
    CONSTRAINT uk_catalogue_vertical__code UNIQUE (code),
    CONSTRAINT ck_catalogue_vertical__code_format CHECK (code ~ '^[A-Z0-9][A-Z0-9._-]*$'),
    CONSTRAINT ck_catalogue_vertical__section_code_format CHECK (section_code ~ '^[A-Z0-9][A-Z0-9._-]*$'),
    CONSTRAINT ck_catalogue_vertical__title CHECK (title = btrim(title) AND char_length(title) > 0),
    CONSTRAINT ck_catalogue_vertical__description CHECK (description = btrim(description) AND char_length(description) > 0),
    CONSTRAINT ck_catalogue_vertical__icon_asset_id CHECK (icon_asset_id = btrim(icon_asset_id) AND char_length(icon_asset_id) > 0),
    CONSTRAINT ck_catalogue_vertical__sort_order CHECK (sort_order >= 0),
    CONSTRAINT ck_catalogue_vertical__availability CHECK (availability IN ('ACTIVE', 'INACTIVE'))
);
CREATE INDEX ix_catalogue_vertical__sort_order_code
    ON app.catalogue_vertical (sort_order, code);
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TABLE app.catalogue_vertical;
--rollback RESET ROLE;

--changeset voxprep:b1-p2-0002-create-learning-goal
SET ROLE voxprep_owner;
CREATE TABLE app.catalogue_learning_goal (
    id uuid NOT NULL,
    version bigint NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    code varchar(128) NOT NULL,
    vertical_id uuid NOT NULL,
    title varchar(256) NOT NULL,
    description varchar(4096) NOT NULL,
    sort_order integer NOT NULL,
    availability varchar(16) NOT NULL,
    CONSTRAINT pk_catalogue_learning_goal PRIMARY KEY (id),
    CONSTRAINT uk_catalogue_learning_goal__code UNIQUE (code),
    CONSTRAINT fk_catalogue_learning_goal__vertical FOREIGN KEY (vertical_id)
        REFERENCES app.catalogue_vertical (id) ON DELETE RESTRICT,
    CONSTRAINT ck_catalogue_learning_goal__code_format CHECK (code ~ '^[A-Z0-9][A-Z0-9._-]*$'),
    CONSTRAINT ck_catalogue_learning_goal__title CHECK (title = btrim(title) AND char_length(title) > 0),
    CONSTRAINT ck_catalogue_learning_goal__description CHECK (description = btrim(description) AND char_length(description) > 0),
    CONSTRAINT ck_catalogue_learning_goal__sort_order CHECK (sort_order >= 0),
    CONSTRAINT ck_catalogue_learning_goal__availability CHECK (availability IN ('ACTIVE', 'INACTIVE'))
);
CREATE INDEX ix_catalogue_learning_goal__vertical_sort_code
    ON app.catalogue_learning_goal (vertical_id, sort_order, code);
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TABLE app.catalogue_learning_goal;
--rollback RESET ROLE;

--changeset voxprep:b1-p2-0003-create-learning-track
SET ROLE voxprep_owner;
CREATE TABLE app.catalogue_learning_track (
    id uuid NOT NULL,
    version bigint NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    code varchar(128) NOT NULL,
    goal_id uuid NOT NULL,
    title varchar(256) NOT NULL,
    description varchar(4096) NOT NULL,
    level_code varchar(128) NOT NULL,
    career_track_code varchar(128),
    sort_order integer NOT NULL,
    availability varchar(16) NOT NULL,
    CONSTRAINT pk_catalogue_learning_track PRIMARY KEY (id),
    CONSTRAINT uk_catalogue_learning_track__code UNIQUE (code),
    CONSTRAINT fk_catalogue_learning_track__goal FOREIGN KEY (goal_id)
        REFERENCES app.catalogue_learning_goal (id) ON DELETE RESTRICT,
    CONSTRAINT ck_catalogue_learning_track__code_format CHECK (code ~ '^[A-Z0-9][A-Z0-9._-]*$'),
    CONSTRAINT ck_catalogue_learning_track__level_code_format CHECK (level_code ~ '^[A-Z0-9][A-Z0-9._-]*$'),
    CONSTRAINT ck_catalogue_learning_track__career_track_code_format CHECK (
        career_track_code IS NULL OR career_track_code ~ '^[A-Z0-9][A-Z0-9._-]*$'),
    CONSTRAINT ck_catalogue_learning_track__title CHECK (title = btrim(title) AND char_length(title) > 0),
    CONSTRAINT ck_catalogue_learning_track__description CHECK (description = btrim(description) AND char_length(description) > 0),
    CONSTRAINT ck_catalogue_learning_track__sort_order CHECK (sort_order >= 0),
    CONSTRAINT ck_catalogue_learning_track__availability CHECK (availability IN ('ACTIVE', 'INACTIVE'))
);
CREATE INDEX ix_catalogue_learning_track__goal_sort_code
    ON app.catalogue_learning_track (goal_id, sort_order, code);
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TABLE app.catalogue_learning_track;
--rollback RESET ROLE;

--changeset voxprep:b1-p2-0004-create-learning-collection
SET ROLE voxprep_owner;
CREATE TABLE app.catalogue_learning_collection (
    id uuid NOT NULL,
    version bigint NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    code varchar(128) NOT NULL,
    track_id uuid NOT NULL,
    title varchar(256) NOT NULL,
    description varchar(4096) NOT NULL,
    access_level varchar(16) NOT NULL,
    sort_order integer NOT NULL,
    availability varchar(16) NOT NULL,
    CONSTRAINT pk_catalogue_learning_collection PRIMARY KEY (id),
    CONSTRAINT uk_catalogue_learning_collection__code UNIQUE (code),
    CONSTRAINT fk_catalogue_learning_collection__track FOREIGN KEY (track_id)
        REFERENCES app.catalogue_learning_track (id) ON DELETE RESTRICT,
    CONSTRAINT ck_catalogue_learning_collection__code_format CHECK (code ~ '^[A-Z0-9][A-Z0-9._-]*$'),
    CONSTRAINT ck_catalogue_learning_collection__title CHECK (title = btrim(title) AND char_length(title) > 0),
    CONSTRAINT ck_catalogue_learning_collection__description CHECK (description = btrim(description) AND char_length(description) > 0),
    CONSTRAINT ck_catalogue_learning_collection__access_level CHECK (access_level IN ('FREE', 'FULL')),
    CONSTRAINT ck_catalogue_learning_collection__sort_order CHECK (sort_order >= 0),
    CONSTRAINT ck_catalogue_learning_collection__availability CHECK (availability IN ('ACTIVE', 'INACTIVE'))
);
CREATE INDEX ix_catalogue_learning_collection__track_sort_code
    ON app.catalogue_learning_collection (track_id, sort_order, code);
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TABLE app.catalogue_learning_collection;
--rollback RESET ROLE;
