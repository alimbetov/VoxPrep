--liquibase formatted sql

--changeset voxprep:b3-p3-0001-assessment-authoring splitStatements:false
SET ROLE voxprep_owner;

ALTER TABLE app.content_revision DROP CONSTRAINT ck_content_revision__content_type;
ALTER TABLE app.content_revision
    ADD CONSTRAINT ck_content_revision__content_type
    CHECK (content_type IN ('vocabulary', 'interview', 'topic', 'phrase', 'shadowing', 'question', 'practice_test'));

CREATE TABLE app.content_question_revision (
    revision_id uuid NOT NULL,
    question_text text NOT NULL,
    explanation text NOT NULL,
    CONSTRAINT pk_content_question_revision PRIMARY KEY (revision_id),
    CONSTRAINT fk_content_question_revision__revision FOREIGN KEY (revision_id)
        REFERENCES app.content_revision (id) ON DELETE CASCADE,
    CONSTRAINT ck_content_question_revision__question CHECK (char_length(btrim(question_text)) > 0),
    CONSTRAINT ck_content_question_revision__explanation CHECK (char_length(btrim(explanation)) > 0)
);

CREATE TABLE app.content_question_option (
    revision_id uuid NOT NULL,
    position integer NOT NULL,
    option_key varchar(64) NOT NULL,
    option_text text NOT NULL,
    is_correct boolean NOT NULL,
    CONSTRAINT pk_content_question_option PRIMARY KEY (revision_id, position),
    CONSTRAINT uk_content_question_option__key UNIQUE (revision_id, option_key),
    CONSTRAINT fk_content_question_option__revision FOREIGN KEY (revision_id)
        REFERENCES app.content_revision (id) ON DELETE CASCADE,
    CONSTRAINT ck_content_question_option__position CHECK (position >= 0),
    CONSTRAINT ck_content_question_option__key CHECK (option_key ~ '^[A-Za-z0-9._-]+$'),
    CONSTRAINT ck_content_question_option__text CHECK (char_length(btrim(option_text)) > 0)
);

CREATE TABLE app.content_practice_test_revision (
    revision_id uuid NOT NULL,
    instructions text NOT NULL,
    passing_score_percent integer NOT NULL,
    CONSTRAINT pk_content_practice_test_revision PRIMARY KEY (revision_id),
    CONSTRAINT fk_content_practice_test_revision__revision FOREIGN KEY (revision_id)
        REFERENCES app.content_revision (id) ON DELETE CASCADE,
    CONSTRAINT ck_content_practice_test_revision__instructions CHECK (char_length(btrim(instructions)) > 0),
    CONSTRAINT ck_content_practice_test_revision__passing_score CHECK (passing_score_percent BETWEEN 1 AND 100)
);

CREATE TABLE app.content_practice_test_question (
    revision_id uuid NOT NULL,
    position integer NOT NULL,
    question_revision_id uuid NOT NULL,
    CONSTRAINT pk_content_practice_test_question PRIMARY KEY (revision_id, position),
    CONSTRAINT uk_content_practice_test_question__question UNIQUE (revision_id, question_revision_id),
    CONSTRAINT fk_content_practice_test_question__revision FOREIGN KEY (revision_id)
        REFERENCES app.content_revision (id) ON DELETE CASCADE,
    CONSTRAINT fk_content_practice_test_question__question FOREIGN KEY (question_revision_id)
        REFERENCES app.content_revision (id) ON DELETE RESTRICT,
    CONSTRAINT ck_content_practice_test_question__position CHECK (position >= 0)
);

CREATE OR REPLACE FUNCTION app.assert_content_revision_body_complete(p_revision_id uuid, p_content_type varchar)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    item_count bigint;
    min_position integer;
    max_position integer;
    correct_count bigint;
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
              FROM app.content_vocabulary_example WHERE revision_id = p_revision_id;
        WHEN 'interview' THEN
            IF NOT EXISTS (SELECT 1 FROM app.content_interview_revision WHERE revision_id = p_revision_id) THEN
                RAISE EXCEPTION 'Interview body is missing' USING ERRCODE = '23514';
            END IF;
            SELECT COUNT(*), MIN(position), MAX(position)
              INTO item_count, min_position, max_position
              FROM app.content_interview_key_point WHERE revision_id = p_revision_id;
        WHEN 'topic' THEN
            IF NOT EXISTS (SELECT 1 FROM app.content_topic_revision WHERE revision_id = p_revision_id) THEN
                RAISE EXCEPTION 'Topic body is missing' USING ERRCODE = '23514';
            END IF;
            SELECT COUNT(*), MIN(position), MAX(position)
              INTO item_count, min_position, max_position
              FROM app.content_topic_section WHERE revision_id = p_revision_id;
        WHEN 'phrase' THEN
            IF NOT EXISTS (SELECT 1 FROM app.content_phrase_revision WHERE revision_id = p_revision_id) THEN
                RAISE EXCEPTION 'Phrase body is missing' USING ERRCODE = '23514';
            END IF;
            SELECT COUNT(*), MIN(position), MAX(position)
              INTO item_count, min_position, max_position
              FROM app.content_phrase_example WHERE revision_id = p_revision_id;
        WHEN 'shadowing' THEN
            IF NOT EXISTS (SELECT 1 FROM app.content_shadowing_revision WHERE revision_id = p_revision_id) THEN
                RAISE EXCEPTION 'Shadowing body is missing' USING ERRCODE = '23514';
            END IF;
            SELECT COUNT(*), MIN(position), MAX(position)
              INTO item_count, min_position, max_position
              FROM app.content_shadowing_segment WHERE revision_id = p_revision_id;
        WHEN 'question' THEN
            IF NOT EXISTS (SELECT 1 FROM app.content_question_revision WHERE revision_id = p_revision_id) THEN
                RAISE EXCEPTION 'Question body is missing' USING ERRCODE = '23514';
            END IF;
            SELECT COUNT(*), MIN(position), MAX(position), COUNT(*) FILTER (WHERE is_correct)
              INTO item_count, min_position, max_position, correct_count
              FROM app.content_question_option WHERE revision_id = p_revision_id;
            IF item_count < 2 OR correct_count < 1 THEN
                RAISE EXCEPTION 'Question must have at least two options and one correct option'
                    USING ERRCODE = '23514';
            END IF;
        WHEN 'practice_test' THEN
            IF NOT EXISTS (SELECT 1 FROM app.content_practice_test_revision WHERE revision_id = p_revision_id) THEN
                RAISE EXCEPTION 'Practice test body is missing' USING ERRCODE = '23514';
            END IF;
            SELECT COUNT(*), MIN(position), MAX(position)
              INTO item_count, min_position, max_position
              FROM app.content_practice_test_question WHERE revision_id = p_revision_id;
            IF EXISTS (
                SELECT 1
                  FROM app.content_practice_test_question member
                  JOIN app.content_revision question ON question.id = member.question_revision_id
                 WHERE member.revision_id = p_revision_id
                   AND question.content_type <> 'question') THEN
                RAISE EXCEPTION 'Practice test may reference only question revisions'
                    USING ERRCODE = '23514';
            END IF;
        ELSE
            RAISE EXCEPTION 'Unsupported content type %', p_content_type USING ERRCODE = '23514';
    END CASE;

    IF item_count < 1 OR min_position <> 0 OR max_position <> item_count - 1 THEN
        RAISE EXCEPTION 'Typed content body items must be non-empty and contiguous from zero'
            USING ERRCODE = '23514';
    END IF;
END;
$$;

CREATE FUNCTION app.practice_test_question_reference_guard()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    referenced_type varchar;
BEGIN
    SELECT content_type INTO referenced_type
      FROM app.content_revision
     WHERE id = NEW.question_revision_id;

    IF referenced_type IS DISTINCT FROM 'question' THEN
        RAISE EXCEPTION 'Practice test may reference only question revisions'
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_content_question_revision__guard
BEFORE INSERT OR UPDATE OR DELETE ON app.content_question_revision
FOR EACH ROW EXECUTE FUNCTION app.content_revision_child_guard('question');
CREATE TRIGGER trg_content_question_option__guard
BEFORE INSERT OR UPDATE OR DELETE ON app.content_question_option
FOR EACH ROW EXECUTE FUNCTION app.content_revision_child_guard('question');

CREATE TRIGGER trg_content_practice_test_revision__guard
BEFORE INSERT OR UPDATE OR DELETE ON app.content_practice_test_revision
FOR EACH ROW EXECUTE FUNCTION app.content_revision_child_guard('practice_test');
CREATE TRIGGER trg_content_practice_test_question__guard
BEFORE INSERT OR UPDATE OR DELETE ON app.content_practice_test_question
FOR EACH ROW EXECUTE FUNCTION app.content_revision_child_guard('practice_test');
CREATE TRIGGER trg_content_practice_test_question__reference_guard
BEFORE INSERT OR UPDATE ON app.content_practice_test_question
FOR EACH ROW EXECUTE FUNCTION app.practice_test_question_reference_guard();

REVOKE ALL ON FUNCTION app.practice_test_question_reference_guard() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.practice_test_question_reference_guard() TO voxprep_backend, voxprep_migrator;

RESET ROLE;

--rollback SET ROLE voxprep_owner;
--rollback DROP TRIGGER trg_content_practice_test_question__reference_guard ON app.content_practice_test_question;
--rollback DROP TRIGGER trg_content_practice_test_question__guard ON app.content_practice_test_question;
--rollback DROP TRIGGER trg_content_practice_test_revision__guard ON app.content_practice_test_revision;
--rollback DROP TRIGGER trg_content_question_option__guard ON app.content_question_option;
--rollback DROP TRIGGER trg_content_question_revision__guard ON app.content_question_revision;
--rollback DROP FUNCTION app.practice_test_question_reference_guard();
--rollback DROP TABLE app.content_practice_test_question;
--rollback DROP TABLE app.content_practice_test_revision;
--rollback DROP TABLE app.content_question_option;
--rollback DROP TABLE app.content_question_revision;
--rollback ALTER TABLE app.content_revision DROP CONSTRAINT ck_content_revision__content_type;
--rollback ALTER TABLE app.content_revision ADD CONSTRAINT ck_content_revision__content_type CHECK (content_type IN ('vocabulary', 'interview', 'topic', 'phrase', 'shadowing'));
--rollback RESET ROLE;
