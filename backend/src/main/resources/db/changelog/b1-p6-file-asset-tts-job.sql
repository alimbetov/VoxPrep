--liquibase formatted sql

--changeset voxprep:b1-p6-0001-create-file-asset
SET ROLE voxprep_owner;
CREATE TABLE app.file_asset (
    id uuid NOT NULL,
    version bigint NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    kind varchar(32) NOT NULL,
    status varchar(32) NOT NULL,
    bucket varchar(128) NOT NULL,
    object_key varchar(1024) NOT NULL,
    media_type varchar(128) NOT NULL,
    size_bytes bigint NOT NULL,
    sha256 varchar(64) NOT NULL,
    CONSTRAINT pk_file_asset PRIMARY KEY (id),
    CONSTRAINT uk_file_asset__storage UNIQUE (bucket, object_key),
    CONSTRAINT ck_file_asset__kind CHECK (kind IN ('TTS_MODEL', 'TTS_CONFIG', 'TTS_AUDIO')),
    CONSTRAINT ck_file_asset__status CHECK (status IN ('REGISTERED', 'READY', 'FAILED', 'QUARANTINED')),
    CONSTRAINT ck_file_asset__bucket CHECK (bucket = btrim(bucket) AND char_length(bucket) > 0),
    CONSTRAINT ck_file_asset__object_key CHECK (object_key = btrim(object_key) AND char_length(object_key) > 0),
    CONSTRAINT ck_file_asset__media_type CHECK (media_type = btrim(media_type) AND char_length(media_type) > 0),
    CONSTRAINT ck_file_asset__size CHECK (size_bytes >= 0),
    CONSTRAINT ck_file_asset__sha256 CHECK (sha256 ~ '^[0-9a-f]{64}$')
);
CREATE INDEX ix_file_asset__kind_status
    ON app.file_asset (kind, status);
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TABLE app.file_asset;
--rollback RESET ROLE;

--changeset voxprep:b1-p6-0002-create-tts-job
SET ROLE voxprep_owner;
CREATE TABLE app.tts_job (
    id uuid NOT NULL,
    version bigint NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    voice_model_id uuid NOT NULL,
    input_text varchar(10000) NOT NULL,
    input_sha256 varchar(64) NOT NULL,
    status varchar(32) NOT NULL,
    output_asset_id uuid,
    CONSTRAINT pk_tts_job PRIMARY KEY (id),
    CONSTRAINT fk_tts_job__voice_model FOREIGN KEY (voice_model_id)
        REFERENCES app.tts_voice_model (id) ON DELETE RESTRICT,
    CONSTRAINT fk_tts_job__output_asset FOREIGN KEY (output_asset_id)
        REFERENCES app.file_asset (id) ON DELETE RESTRICT,
    CONSTRAINT ck_tts_job__input_text CHECK (input_text = btrim(input_text) AND char_length(input_text) > 0),
    CONSTRAINT ck_tts_job__input_sha256 CHECK (input_sha256 ~ '^[0-9a-f]{64}$'),
    CONSTRAINT ck_tts_job__status CHECK (status IN ('PENDING', 'CLAIMED', 'PROCESSING', 'READY', 'FAILED')),
    CONSTRAINT ck_tts_job__output_state CHECK (
        (status = 'READY' AND output_asset_id IS NOT NULL)
        OR (status <> 'READY' AND output_asset_id IS NULL))
);
CREATE INDEX ix_tts_job__status_created
    ON app.tts_job (status, created_at, id);
CREATE INDEX ix_tts_job__voice_model
    ON app.tts_job (voice_model_id);
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TABLE app.tts_job;
--rollback RESET ROLE;
