const practiceTestAttemptSchemaV13Statements = <String>[
  '''
  CREATE TABLE IF NOT EXISTS practice_test_active_attempt (
    id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1),
    practice_test_code TEXT NOT NULL CHECK (length(trim(practice_test_code)) > 0),
    practice_test_revision INTEGER NOT NULL CHECK (practice_test_revision > 0),
    current_index INTEGER NOT NULL CHECK (current_index >= 0),
    answers_json TEXT NOT NULL CHECK (length(trim(answers_json)) > 0),
    started_at INTEGER NOT NULL CHECK (started_at > 0),
    updated_at INTEGER NOT NULL CHECK (updated_at >= started_at)
  )
  ''',
];
