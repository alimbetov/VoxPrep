--liquibase formatted sql

--changeset voxprep:api-r3-0001-assessment-delivery-config
SET ROLE voxprep_owner;
CREATE TABLE app.assessment_delivery_config (
    test_revision_id uuid PRIMARY KEY
        REFERENCES app.content_practice_test_revision(revision_id) ON DELETE RESTRICT,
    mode varchar(8) NOT NULL
        CHECK (mode IN ('learn', 'exam', 'quick')),
    points_json jsonb NOT NULL
        CHECK (jsonb_typeof(points_json) = 'array'
            AND jsonb_array_length(points_json) > 0),
    updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE app.publication_wire_document
    DROP CONSTRAINT ck_publication_wire_document__kind;
ALTER TABLE app.publication_wire_document
    ADD CONSTRAINT ck_publication_wire_document__kind
    CHECK (document_kind IN ('ROOT', 'PACK', 'CATALOGUE', 'ASSESSMENT'));
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback ALTER TABLE app.publication_wire_document DROP CONSTRAINT ck_publication_wire_document__kind;
--rollback ALTER TABLE app.publication_wire_document ADD CONSTRAINT ck_publication_wire_document__kind CHECK (document_kind IN ('ROOT', 'PACK', 'CATALOGUE'));
--rollback DROP TABLE app.assessment_delivery_config;
--rollback RESET ROLE;

--changeset voxprep:api-r3-0002-published-assessment-config-guard splitStatements:false
SET ROLE voxprep_owner;
CREATE FUNCTION app.assessment_delivery_config_published_guard()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM app.content_revision
         WHERE id = COALESCE(NEW.test_revision_id, OLD.test_revision_id)
           AND published_at IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'published assessment delivery config is immutable'
            USING ERRCODE = '23514';
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$;
CREATE TRIGGER trg_assessment_delivery_config_immutable
BEFORE INSERT OR UPDATE OR DELETE ON app.assessment_delivery_config
FOR EACH ROW EXECUTE FUNCTION app.assessment_delivery_config_published_guard();
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TRIGGER trg_assessment_delivery_config_immutable ON app.assessment_delivery_config;
--rollback DROP FUNCTION app.assessment_delivery_config_published_guard();
--rollback RESET ROLE;
