--liquibase formatted sql

--changeset voxprep:b5-p2-0001-enforce-active-tts-model-policy
SET ROLE voxprep_owner;
ALTER TABLE app.tts_voice_model
    ADD CONSTRAINT ck_tts_voice_model__active_policy CHECK (
        status <> 'ACTIVE'
        OR (
            source_provider IS NOT NULL
            AND source_provider = btrim(source_provider)
            AND char_length(source_provider) > 0
            AND source_repository IS NOT NULL
            AND source_repository = btrim(source_repository)
            AND char_length(source_repository) > 0
            AND source_revision IS NOT NULL
            AND source_revision = btrim(source_revision)
            AND char_length(source_revision) > 0
            AND license_name IS NOT NULL
            AND license_name = btrim(license_name)
            AND char_length(license_name) > 0
            AND license_reference IS NOT NULL
            AND license_reference = btrim(license_reference)
            AND char_length(license_reference) > 0
            AND commercial_use_reviewed
            AND approved_at IS NOT NULL
        )
    );
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback ALTER TABLE app.tts_voice_model DROP CONSTRAINT ck_tts_voice_model__active_policy;
--rollback RESET ROLE;
