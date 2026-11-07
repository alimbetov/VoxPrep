--liquibase formatted sql

--changeset voxprep:k1-kokoro-0005-immutable-job-voice-snapshot splitStatements:false
-- A Kokoro job must retain a frozen model bundle/voice/fingerprint at enqueue.
-- This is additive and does not change any historical Piper rows.
SET ROLE voxprep_owner;
CREATE TABLE app.tts_kokoro_job_snapshot (
    job_id uuid PRIMARY KEY REFERENCES app.tts_job(id) ON DELETE RESTRICT,
    voice_model_id uuid NOT NULL
        REFERENCES app.tts_kokoro_model_binding(voice_model_id) ON DELETE RESTRICT,
    bundle_id uuid NOT NULL
        REFERENCES app.tts_kokoro_bundle(id) ON DELETE RESTRICT,
    manifest_sha256 varchar(64) NOT NULL,
    voice_code varchar(64) NOT NULL,
    voice_artifact_sha256 varchar(64) NOT NULL,
    phonemizer_version varchar(128) NOT NULL,
    engine_version varchar(64) NOT NULL,
    speed numeric(5,3) NOT NULL,
    fingerprint_version varchar(32) NOT NULL DEFAULT 'tts-fingerprint-v2',
    fingerprint varchar(64) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_tts_kokoro_snapshot_manifest
        CHECK (manifest_sha256 ~ '^[0-9a-f]{64}$'),
    CONSTRAINT ck_tts_kokoro_snapshot_voice_hash
        CHECK (voice_artifact_sha256 ~ '^[0-9a-f]{64}$'),
    CONSTRAINT ck_tts_kokoro_snapshot_fingerprint
        CHECK (fingerprint ~ '^[0-9a-f]{64}$'
               AND fingerprint_version = 'tts-fingerprint-v2'),
    CONSTRAINT ck_tts_kokoro_snapshot_speed
        CHECK (speed BETWEEN 0.500 AND 2.000)
);
CREATE FUNCTION app.tts_kokoro_snapshot_immutable()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP <> 'INSERT' THEN
        RAISE EXCEPTION 'Kokoro job snapshots are append-only'
            USING ERRCODE = '23514';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM app.tts_job j
          JOIN app.tts_voice_model vm ON vm.id = j.voice_model_id
          JOIN app.tts_kokoro_model_binding binding
            ON binding.voice_model_id = vm.id
          JOIN app.tts_kokoro_bundle bundle ON bundle.id = binding.bundle_id
          JOIN app.tts_kokoro_bundle_artifact voice
            ON voice.bundle_id = binding.bundle_id
           AND voice.logical_path = binding.voice_artifact_path
         WHERE j.id = NEW.job_id
           AND j.status = 'PENDING'
           AND j.fingerprint = NEW.fingerprint
           AND j.voice_model_id = NEW.voice_model_id
           AND vm.engine = 'KOKORO'
           AND binding.bundle_id = NEW.bundle_id
           AND binding.voice_code = NEW.voice_code
           AND binding.phonemizer_version = NEW.phonemizer_version
           AND vm.engine_version = NEW.engine_version
           AND bundle.status = 'STAGED'
           AND bundle.manifest_sha256 = NEW.manifest_sha256
           AND voice.sha256 = NEW.voice_artifact_sha256
    ) THEN
        RAISE EXCEPTION 'Kokoro snapshot differs from its pinned job/model/bundle'
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_tts_kokoro_snapshot_immutable
BEFORE INSERT OR UPDATE OR DELETE ON app.tts_kokoro_job_snapshot
FOR EACH ROW EXECUTE FUNCTION app.tts_kokoro_snapshot_immutable();
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TRIGGER trg_tts_kokoro_snapshot_immutable ON app.tts_kokoro_job_snapshot;
--rollback DROP FUNCTION app.tts_kokoro_snapshot_immutable();
--rollback DROP TABLE app.tts_kokoro_job_snapshot;
--rollback RESET ROLE;
