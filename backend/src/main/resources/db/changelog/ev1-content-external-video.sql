--liquibase formatted sql
--changeset voxprep:ev1-0001-external-learning-video splitStatements:false
SET ROLE voxprep_owner;
CREATE TABLE app.content_external_video (
    content_revision_id uuid PRIMARY KEY REFERENCES app.content_revision(id) ON DELETE RESTRICT,
    provider varchar(20) NOT NULL DEFAULT 'YOUTUBE',
    provider_video_id varchar(11) NOT NULL,
    title varchar(160) NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_external_video_provider CHECK (provider = 'YOUTUBE'),
    CONSTRAINT ck_external_video_id CHECK (provider_video_id ~ '^[A-Za-z0-9_-]{11}$'),
    CONSTRAINT ck_external_video_title CHECK (char_length(btrim(title)) BETWEEN 1 AND 160)
);
CREATE FUNCTION app.guard_external_video_draft() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE current_state varchar(32);
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.content_revision_id IS DISTINCT FROM OLD.content_revision_id THEN
        RAISE EXCEPTION 'Video revision identity cannot change' USING ERRCODE='23514';
    END IF;
    SELECT lifecycle INTO current_state FROM app.content_revision
        WHERE id = CASE WHEN TG_OP = 'DELETE' THEN OLD.content_revision_id ELSE NEW.content_revision_id END
        FOR UPDATE;
    IF current_state IS DISTINCT FROM 'DRAFT' THEN
        RAISE EXCEPTION 'External video is editable only on DRAFT revisions' USING ERRCODE='23514';
    END IF;
    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$;
CREATE TRIGGER trg_external_video_draft
BEFORE INSERT OR UPDATE OR DELETE ON app.content_external_video
FOR EACH ROW EXECUTE FUNCTION app.guard_external_video_draft();
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TABLE app.content_external_video CASCADE;
--rollback DROP FUNCTION app.guard_external_video_draft();
--rollback RESET ROLE;
