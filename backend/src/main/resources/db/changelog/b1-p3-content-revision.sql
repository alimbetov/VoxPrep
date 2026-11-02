--liquibase formatted sql

--changeset voxprep:b1-p3-0001-create-content-revision-tables
SET ROLE voxprep_owner;

CREATE TABLE app.content_revision (
    id uuid NOT NULL,
    version bigint NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    content_code varchar(128) NOT NULL,
    content_type varchar(32) NOT NULL,
    revision_number integer NOT NULL,
    lifecycle varchar(32) NOT NULL,
    checksum_sha256 varchar(64) NOT NULL,
    title varchar(256) NOT NULL,
    subtitle varchar(512) NOT NULL,
    description varchar(4096) NOT NULL,
    category_code varchar(128) NOT NULL,
    level_code varchar(128) NOT NULL,
    minutes integer NOT NULL,
    availability varchar(16) NOT NULL,
    published_at timestamptz,
    CONSTRAINT pk_content_revision PRIMARY KEY (id),
    CONSTRAINT uk_content_revision__identity UNIQUE (content_code, content_type, revision_number),
    CONSTRAINT ck_content_revision__content_code CHECK (content_code ~ '^[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_content_revision__content_type CHECK (content_type IN ('vocabulary', 'interview', 'topic', 'phrase', 'shadowing')),
    CONSTRAINT ck_content_revision__revision CHECK (revision_number >= 1),
    CONSTRAINT ck_content_revision__lifecycle CHECK (lifecycle IN ('DRAFT', 'READY_FOR_AUDIO', 'READY_FOR_REVIEW', 'PUBLISHED', 'ARCHIVED')),
    CONSTRAINT ck_content_revision__checksum CHECK (checksum_sha256 ~ '^[0-9a-f]{64}$'),
    CONSTRAINT ck_content_revision__title CHECK (char_length(btrim(title)) > 0),
    CONSTRAINT ck_content_revision__subtitle CHECK (char_length(btrim(subtitle)) > 0),
    CONSTRAINT ck_content_revision__description CHECK (char_length(btrim(description)) > 0),
    CONSTRAINT ck_content_revision__category_code CHECK (category_code ~ '^[A-Z0-9][A-Z0-9._-]*$'),
    CONSTRAINT ck_content_revision__level_code CHECK (level_code ~ '^[A-Z0-9][A-Z0-9._-]*$'),
    CONSTRAINT ck_content_revision__minutes CHECK (minutes >= 1),
    CONSTRAINT ck_content_revision__availability CHECK (availability IN ('ACTIVE', 'INACTIVE')),
    CONSTRAINT ck_content_revision__published_at CHECK (
        (lifecycle IN ('PUBLISHED', 'ARCHIVED') AND published_at IS NOT NULL)
        OR (lifecycle NOT IN ('PUBLISHED', 'ARCHIVED') AND published_at IS NULL))
);

CREATE INDEX ix_content_revision__lifecycle_availability
    ON app.content_revision (lifecycle, availability);

CREATE TABLE app.content_revision_skill (
    revision_id uuid NOT NULL,
    position integer NOT NULL,
    skill_code varchar(128) NOT NULL,
    CONSTRAINT pk_content_revision_skill PRIMARY KEY (revision_id, position),
    CONSTRAINT uk_content_revision_skill__skill UNIQUE (revision_id, skill_code),
    CONSTRAINT fk_content_revision_skill__revision FOREIGN KEY (revision_id)
        REFERENCES app.content_revision (id) ON DELETE CASCADE,
    CONSTRAINT ck_content_revision_skill__position CHECK (position >= 0),
    CONSTRAINT ck_content_revision_skill__code CHECK (skill_code ~ '^[A-Z0-9][A-Z0-9._-]*$')
);

CREATE TABLE app.content_vocabulary_revision (
    revision_id uuid NOT NULL,
    term text NOT NULL,
    definition text NOT NULL,
    part_of_speech varchar(128),
    CONSTRAINT pk_content_vocabulary_revision PRIMARY KEY (revision_id),
    CONSTRAINT fk_content_vocabulary_revision__revision FOREIGN KEY (revision_id)
        REFERENCES app.content_revision (id) ON DELETE CASCADE,
    CONSTRAINT ck_content_vocabulary_revision__term CHECK (char_length(btrim(term)) > 0),
    CONSTRAINT ck_content_vocabulary_revision__definition CHECK (char_length(btrim(definition)) > 0),
    CONSTRAINT ck_content_vocabulary_revision__part_of_speech CHECK (
        part_of_speech IS NULL OR char_length(btrim(part_of_speech)) > 0)
);

CREATE TABLE app.content_vocabulary_example (
    revision_id uuid NOT NULL,
    position integer NOT NULL,
    example_text text NOT NULL,
    CONSTRAINT pk_content_vocabulary_example PRIMARY KEY (revision_id, position),
    CONSTRAINT fk_content_vocabulary_example__revision FOREIGN KEY (revision_id)
        REFERENCES app.content_revision (id) ON DELETE CASCADE,
    CONSTRAINT ck_content_vocabulary_example__position CHECK (position >= 0),
    CONSTRAINT ck_content_vocabulary_example__text CHECK (char_length(btrim(example_text)) > 0)
);

CREATE TABLE app.content_interview_revision (
    revision_id uuid NOT NULL,
    prompt text NOT NULL,
    model_answer text NOT NULL,
    CONSTRAINT pk_content_interview_revision PRIMARY KEY (revision_id),
    CONSTRAINT fk_content_interview_revision__revision FOREIGN KEY (revision_id)
        REFERENCES app.content_revision (id) ON DELETE CASCADE,
    CONSTRAINT ck_content_interview_revision__prompt CHECK (char_length(btrim(prompt)) > 0),
    CONSTRAINT ck_content_interview_revision__model_answer CHECK (char_length(btrim(model_answer)) > 0)
);

CREATE TABLE app.content_interview_key_point (
    revision_id uuid NOT NULL,
    position integer NOT NULL,
    key_point text NOT NULL,
    CONSTRAINT pk_content_interview_key_point PRIMARY KEY (revision_id, position),
    CONSTRAINT fk_content_interview_key_point__revision FOREIGN KEY (revision_id)
        REFERENCES app.content_revision (id) ON DELETE CASCADE,
    CONSTRAINT ck_content_interview_key_point__position CHECK (position >= 0),
    CONSTRAINT ck_content_interview_key_point__text CHECK (char_length(btrim(key_point)) > 0)
);

CREATE TABLE app.content_topic_revision (
    revision_id uuid NOT NULL,
    CONSTRAINT pk_content_topic_revision PRIMARY KEY (revision_id),
    CONSTRAINT fk_content_topic_revision__revision FOREIGN KEY (revision_id)
        REFERENCES app.content_revision (id) ON DELETE CASCADE
);

CREATE TABLE app.content_topic_section (
    revision_id uuid NOT NULL,
    position integer NOT NULL,
    heading text NOT NULL,
    section_text text NOT NULL,
    CONSTRAINT pk_content_topic_section PRIMARY KEY (revision_id, position),
    CONSTRAINT fk_content_topic_section__revision FOREIGN KEY (revision_id)
        REFERENCES app.content_revision (id) ON DELETE CASCADE,
    CONSTRAINT ck_content_topic_section__position CHECK (position >= 0),
    CONSTRAINT ck_content_topic_section__heading CHECK (char_length(btrim(heading)) > 0),
    CONSTRAINT ck_content_topic_section__text CHECK (char_length(btrim(section_text)) > 0)
);

CREATE TABLE app.content_phrase_revision (
    revision_id uuid NOT NULL,
    phrase text NOT NULL,
    usage text NOT NULL,
    CONSTRAINT pk_content_phrase_revision PRIMARY KEY (revision_id),
    CONSTRAINT fk_content_phrase_revision__revision FOREIGN KEY (revision_id)
        REFERENCES app.content_revision (id) ON DELETE CASCADE,
    CONSTRAINT ck_content_phrase_revision__phrase CHECK (char_length(btrim(phrase)) > 0),
    CONSTRAINT ck_content_phrase_revision__usage CHECK (char_length(btrim(usage)) > 0)
);

CREATE TABLE app.content_phrase_example (
    revision_id uuid NOT NULL,
    position integer NOT NULL,
    example_text text NOT NULL,
    CONSTRAINT pk_content_phrase_example PRIMARY KEY (revision_id, position),
    CONSTRAINT fk_content_phrase_example__revision FOREIGN KEY (revision_id)
        REFERENCES app.content_revision (id) ON DELETE CASCADE,
    CONSTRAINT ck_content_phrase_example__position CHECK (position >= 0),
    CONSTRAINT ck_content_phrase_example__text CHECK (char_length(btrim(example_text)) > 0)
);

CREATE TABLE app.content_shadowing_revision (
    revision_id uuid NOT NULL,
    transcript text NOT NULL,
    CONSTRAINT pk_content_shadowing_revision PRIMARY KEY (revision_id),
    CONSTRAINT fk_content_shadowing_revision__revision FOREIGN KEY (revision_id)
        REFERENCES app.content_revision (id) ON DELETE CASCADE,
    CONSTRAINT ck_content_shadowing_revision__transcript CHECK (char_length(btrim(transcript)) > 0)
);

CREATE TABLE app.content_shadowing_segment (
    revision_id uuid NOT NULL,
    position integer NOT NULL,
    segment_text text NOT NULL,
    start_ms integer,
    end_ms integer,
    CONSTRAINT pk_content_shadowing_segment PRIMARY KEY (revision_id, position),
    CONSTRAINT fk_content_shadowing_segment__revision FOREIGN KEY (revision_id)
        REFERENCES app.content_revision (id) ON DELETE CASCADE,
    CONSTRAINT ck_content_shadowing_segment__position CHECK (position >= 0),
    CONSTRAINT ck_content_shadowing_segment__text CHECK (char_length(btrim(segment_text)) > 0),
    CONSTRAINT ck_content_shadowing_segment__start CHECK (start_ms IS NULL OR start_ms >= 0),
    CONSTRAINT ck_content_shadowing_segment__end CHECK (end_ms IS NULL OR end_ms >= 1),
    CONSTRAINT ck_content_shadowing_segment__range CHECK (
        start_ms IS NULL OR end_ms IS NULL OR end_ms > start_ms)
);

RESET ROLE;

--rollback SET ROLE voxprep_owner;
--rollback DROP TABLE app.content_shadowing_segment;
--rollback DROP TABLE app.content_shadowing_revision;
--rollback DROP TABLE app.content_phrase_example;
--rollback DROP TABLE app.content_phrase_revision;
--rollback DROP TABLE app.content_topic_section;
--rollback DROP TABLE app.content_topic_revision;
--rollback DROP TABLE app.content_interview_key_point;
--rollback DROP TABLE app.content_interview_revision;
--rollback DROP TABLE app.content_vocabulary_example;
--rollback DROP TABLE app.content_vocabulary_revision;
--rollback DROP TABLE app.content_revision_skill;
--rollback DROP TABLE app.content_revision;
--rollback RESET ROLE;

--changeset voxprep:b1-p3-0002-content-revision-integrity splitStatements:false
SET ROLE voxprep_owner;

CREATE FUNCTION app.content_revision_next_number_guard()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    expected_revision integer;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtextextended(NEW.content_code || '|' || NEW.content_type, 0));

    SELECT COALESCE(MAX(revision_number), 0) + 1
      INTO expected_revision
      FROM app.content_revision
     WHERE content_code = NEW.content_code
       AND content_type = NEW.content_type;

    IF NEW.revision_number <> expected_revision THEN
        RAISE EXCEPTION 'Content revision must be %, got % for %/%',
            expected_revision, NEW.revision_number, NEW.content_code, NEW.content_type
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

CREATE FUNCTION app.assert_content_revision_body_complete(p_revision_id uuid, p_content_type varchar)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    item_count bigint;
    min_position integer;
    max_position integer;
BEGIN
    SELECT COUNT(*), MIN(position), MAX(position)
      INTO item_count, min_position, max_position
      FROM app.content_revision_skill
     WHERE revision_id = p_revision_id;

    IF item_count > 0 AND (min_position <> 0 OR max_position <> item_count - 1) THEN
        RAISE EXCEPTION 'Content skill positions must be contiguous from zero'
            USING ERRCODE = '23514';
    END IF;

    CASE p_content_type
        WHEN 'vocabulary' THEN
            IF NOT EXISTS (SELECT 1 FROM app.content_vocabulary_revision WHERE revision_id = p_revision_id) THEN
                RAISE EXCEPTION 'Vocabulary body is missing' USING ERRCODE = '23514';
            END IF;
            SELECT COUNT(*), MIN(position), MAX(position)
              INTO item_count, min_position, max_position
              FROM app.content_vocabulary_example
             WHERE revision_id = p_revision_id;
        WHEN 'interview' THEN
            IF NOT EXISTS (SELECT 1 FROM app.content_interview_revision WHERE revision_id = p_revision_id) THEN
                RAISE EXCEPTION 'Interview body is missing' USING ERRCODE = '23514';
            END IF;
            SELECT COUNT(*), MIN(position), MAX(position)
              INTO item_count, min_position, max_position
              FROM app.content_interview_key_point
             WHERE revision_id = p_revision_id;
        WHEN 'topic' THEN
            IF NOT EXISTS (SELECT 1 FROM app.content_topic_revision WHERE revision_id = p_revision_id) THEN
                RAISE EXCEPTION 'Topic body is missing' USING ERRCODE = '23514';
            END IF;
            SELECT COUNT(*), MIN(position), MAX(position)
              INTO item_count, min_position, max_position
              FROM app.content_topic_section
             WHERE revision_id = p_revision_id;
        WHEN 'phrase' THEN
            IF NOT EXISTS (SELECT 1 FROM app.content_phrase_revision WHERE revision_id = p_revision_id) THEN
                RAISE EXCEPTION 'Phrase body is missing' USING ERRCODE = '23514';
            END IF;
            SELECT COUNT(*), MIN(position), MAX(position)
              INTO item_count, min_position, max_position
              FROM app.content_phrase_example
             WHERE revision_id = p_revision_id;
        WHEN 'shadowing' THEN
            IF NOT EXISTS (SELECT 1 FROM app.content_shadowing_revision WHERE revision_id = p_revision_id) THEN
                RAISE EXCEPTION 'Shadowing body is missing' USING ERRCODE = '23514';
            END IF;
            SELECT COUNT(*), MIN(position), MAX(position)
              INTO item_count, min_position, max_position
              FROM app.content_shadowing_segment
             WHERE revision_id = p_revision_id;
        ELSE
            RAISE EXCEPTION 'Unsupported content type %', p_content_type USING ERRCODE = '23514';
    END CASE;

    IF item_count < 1 OR min_position <> 0 OR max_position <> item_count - 1 THEN
        RAISE EXCEPTION 'Typed content body items must be non-empty and contiguous from zero'
            USING ERRCODE = '23514';
    END IF;
END;
$$;

CREATE FUNCTION app.content_revision_mutation_guard()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'Content revisions are append-only and cannot be hard deleted'
            USING ERRCODE = '23514';
    END IF;

    IF NEW.content_code IS DISTINCT FROM OLD.content_code
       OR NEW.content_type IS DISTINCT FROM OLD.content_type
       OR NEW.revision_number IS DISTINCT FROM OLD.revision_number THEN
        RAISE EXCEPTION 'Content revision exact identity is immutable'
            USING ERRCODE = '23514';
    END IF;

    IF OLD.lifecycle <> 'DRAFT' AND (
        NEW.checksum_sha256 IS DISTINCT FROM OLD.checksum_sha256
        OR NEW.title IS DISTINCT FROM OLD.title
        OR NEW.subtitle IS DISTINCT FROM OLD.subtitle
        OR NEW.description IS DISTINCT FROM OLD.description
        OR NEW.category_code IS DISTINCT FROM OLD.category_code
        OR NEW.level_code IS DISTINCT FROM OLD.level_code
        OR NEW.minutes IS DISTINCT FROM OLD.minutes) THEN
        RAISE EXCEPTION 'Frozen content revision payload is immutable after DRAFT'
            USING ERRCODE = '23514';
    END IF;

    IF OLD.published_at IS NOT NULL AND NEW.published_at IS DISTINCT FROM OLD.published_at THEN
        RAISE EXCEPTION 'published_at is immutable once assigned'
            USING ERRCODE = '23514';
    END IF;

    IF NEW.lifecycle IS DISTINCT FROM OLD.lifecycle THEN
        IF NOT (
            (OLD.lifecycle = 'DRAFT' AND NEW.lifecycle = 'READY_FOR_AUDIO')
            OR (OLD.lifecycle = 'READY_FOR_AUDIO' AND NEW.lifecycle = 'READY_FOR_REVIEW')
            OR (OLD.lifecycle = 'READY_FOR_REVIEW' AND NEW.lifecycle = 'PUBLISHED')
            OR (OLD.lifecycle = 'PUBLISHED' AND NEW.lifecycle = 'ARCHIVED')) THEN
            RAISE EXCEPTION 'Invalid content lifecycle transition: % -> %', OLD.lifecycle, NEW.lifecycle
                USING ERRCODE = '23514';
        END IF;
    END IF;

    IF OLD.lifecycle = 'DRAFT' AND NEW.lifecycle = 'READY_FOR_AUDIO' THEN
        PERFORM app.assert_content_revision_body_complete(NEW.id, NEW.content_type);
    END IF;

    RETURN NEW;
END;
$$;

CREATE FUNCTION app.content_revision_child_guard()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    target_revision uuid;
    expected_type varchar;
    actual_type varchar;
    actual_lifecycle varchar;
BEGIN
    target_revision := COALESCE(NEW.revision_id, OLD.revision_id);
    expected_type := TG_ARGV[0];

    SELECT content_type, lifecycle
      INTO actual_type, actual_lifecycle
      FROM app.content_revision
     WHERE id = target_revision;

    IF actual_type IS NULL THEN
        RETURN COALESCE(NEW, OLD);
    END IF;

    IF expected_type <> '' AND actual_type <> expected_type THEN
        RAISE EXCEPTION 'Typed body % cannot be attached to content type %', expected_type, actual_type
            USING ERRCODE = '23514';
    END IF;

    IF actual_lifecycle <> 'DRAFT' THEN
        RAISE EXCEPTION 'Content revision child rows are immutable after DRAFT'
            USING ERRCODE = '23514';
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER trg_content_revision__next_number
BEFORE INSERT ON app.content_revision
FOR EACH ROW EXECUTE FUNCTION app.content_revision_next_number_guard();

CREATE TRIGGER trg_content_revision__mutation_guard
BEFORE UPDATE OR DELETE ON app.content_revision
FOR EACH ROW EXECUTE FUNCTION app.content_revision_mutation_guard();

CREATE TRIGGER trg_content_revision_skill__guard
BEFORE INSERT OR UPDATE OR DELETE ON app.content_revision_skill
FOR EACH ROW EXECUTE FUNCTION app.content_revision_child_guard('');

CREATE TRIGGER trg_content_vocabulary_revision__guard
BEFORE INSERT OR UPDATE OR DELETE ON app.content_vocabulary_revision
FOR EACH ROW EXECUTE FUNCTION app.content_revision_child_guard('vocabulary');
CREATE TRIGGER trg_content_vocabulary_example__guard
BEFORE INSERT OR UPDATE OR DELETE ON app.content_vocabulary_example
FOR EACH ROW EXECUTE FUNCTION app.content_revision_child_guard('vocabulary');

CREATE TRIGGER trg_content_interview_revision__guard
BEFORE INSERT OR UPDATE OR DELETE ON app.content_interview_revision
FOR EACH ROW EXECUTE FUNCTION app.content_revision_child_guard('interview');
CREATE TRIGGER trg_content_interview_key_point__guard
BEFORE INSERT OR UPDATE OR DELETE ON app.content_interview_key_point
FOR EACH ROW EXECUTE FUNCTION app.content_revision_child_guard('interview');

CREATE TRIGGER trg_content_topic_revision__guard
BEFORE INSERT OR UPDATE OR DELETE ON app.content_topic_revision
FOR EACH ROW EXECUTE FUNCTION app.content_revision_child_guard('topic');
CREATE TRIGGER trg_content_topic_section__guard
BEFORE INSERT OR UPDATE OR DELETE ON app.content_topic_section
FOR EACH ROW EXECUTE FUNCTION app.content_revision_child_guard('topic');

CREATE TRIGGER trg_content_phrase_revision__guard
BEFORE INSERT OR UPDATE OR DELETE ON app.content_phrase_revision
FOR EACH ROW EXECUTE FUNCTION app.content_revision_child_guard('phrase');
CREATE TRIGGER trg_content_phrase_example__guard
BEFORE INSERT OR UPDATE OR DELETE ON app.content_phrase_example
FOR EACH ROW EXECUTE FUNCTION app.content_revision_child_guard('phrase');

CREATE TRIGGER trg_content_shadowing_revision__guard
BEFORE INSERT OR UPDATE OR DELETE ON app.content_shadowing_revision
FOR EACH ROW EXECUTE FUNCTION app.content_revision_child_guard('shadowing');
CREATE TRIGGER trg_content_shadowing_segment__guard
BEFORE INSERT OR UPDATE OR DELETE ON app.content_shadowing_segment
FOR EACH ROW EXECUTE FUNCTION app.content_revision_child_guard('shadowing');

REVOKE ALL ON FUNCTION app.content_revision_next_number_guard() FROM PUBLIC;
REVOKE ALL ON FUNCTION app.assert_content_revision_body_complete(uuid, varchar) FROM PUBLIC;
REVOKE ALL ON FUNCTION app.content_revision_mutation_guard() FROM PUBLIC;
REVOKE ALL ON FUNCTION app.content_revision_child_guard() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.content_revision_next_number_guard() TO voxprep_backend, voxprep_migrator;
GRANT EXECUTE ON FUNCTION app.assert_content_revision_body_complete(uuid, varchar) TO voxprep_backend, voxprep_migrator;
GRANT EXECUTE ON FUNCTION app.content_revision_mutation_guard() TO voxprep_backend, voxprep_migrator;
GRANT EXECUTE ON FUNCTION app.content_revision_child_guard() TO voxprep_backend, voxprep_migrator;

RESET ROLE;

--rollback SET ROLE voxprep_owner;
--rollback DROP TRIGGER trg_content_shadowing_segment__guard ON app.content_shadowing_segment;
--rollback DROP TRIGGER trg_content_shadowing_revision__guard ON app.content_shadowing_revision;
--rollback DROP TRIGGER trg_content_phrase_example__guard ON app.content_phrase_example;
--rollback DROP TRIGGER trg_content_phrase_revision__guard ON app.content_phrase_revision;
--rollback DROP TRIGGER trg_content_topic_section__guard ON app.content_topic_section;
--rollback DROP TRIGGER trg_content_topic_revision__guard ON app.content_topic_revision;
--rollback DROP TRIGGER trg_content_interview_key_point__guard ON app.content_interview_key_point;
--rollback DROP TRIGGER trg_content_interview_revision__guard ON app.content_interview_revision;
--rollback DROP TRIGGER trg_content_vocabulary_example__guard ON app.content_vocabulary_example;
--rollback DROP TRIGGER trg_content_vocabulary_revision__guard ON app.content_vocabulary_revision;
--rollback DROP TRIGGER trg_content_revision_skill__guard ON app.content_revision_skill;
--rollback DROP TRIGGER trg_content_revision__mutation_guard ON app.content_revision;
--rollback DROP TRIGGER trg_content_revision__next_number ON app.content_revision;
--rollback DROP FUNCTION app.content_revision_child_guard();
--rollback DROP FUNCTION app.content_revision_mutation_guard();
--rollback DROP FUNCTION app.assert_content_revision_body_complete(uuid, varchar);
--rollback DROP FUNCTION app.content_revision_next_number_guard();
--rollback RESET ROLE;
