--liquibase formatted sql

--changeset voxprep:k1-kokoro-0002-bundle-staging
-- Kokoro provisioning is staging-only. A completed bundle is not an ACTIVE voice model.
SET ROLE voxprep_owner;
CREATE TABLE app.tts_kokoro_bundle (
    id uuid PRIMARY KEY,
    model_code varchar(128) NOT NULL UNIQUE,
    manifest_sha256 varchar(64) NOT NULL,
    source_repository varchar(256) NOT NULL,
    source_revision varchar(128) NOT NULL,
    license_name varchar(256) NOT NULL,
    license_reference varchar(1024) NOT NULL,
    status varchar(32) NOT NULL DEFAULT 'STAGED',
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_tts_kokoro_bundle_hash CHECK (manifest_sha256 ~ '^[0-9a-f]{64}$'),
    CONSTRAINT ck_tts_kokoro_bundle_status CHECK (status IN ('STAGED'))
);
CREATE TABLE app.tts_kokoro_bundle_artifact (
    bundle_id uuid NOT NULL REFERENCES app.tts_kokoro_bundle(id) ON DELETE RESTRICT,
    logical_path varchar(256) NOT NULL,
    artifact_role varchar(64) NOT NULL,
    file_asset_id uuid NOT NULL REFERENCES app.file_asset(id) ON DELETE RESTRICT,
    sha256 varchar(64) NOT NULL,
    size_bytes bigint NOT NULL,
    media_type varchar(128) NOT NULL,
    PRIMARY KEY (bundle_id, logical_path),
    CONSTRAINT ck_tts_kokoro_artifact_hash CHECK (sha256 ~ '^[0-9a-f]{64}$'),
    CONSTRAINT ck_tts_kokoro_artifact_size CHECK (size_bytes > 0)
);
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TABLE app.tts_kokoro_bundle_artifact;
--rollback DROP TABLE app.tts_kokoro_bundle;
--rollback RESET ROLE;
