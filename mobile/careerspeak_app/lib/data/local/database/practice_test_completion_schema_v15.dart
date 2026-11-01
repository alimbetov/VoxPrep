const practiceTestCompletionSchemaV15Statements = <String>[
  '''
  CREATE TABLE IF NOT EXISTS practice_test_completions (
    practice_test_code TEXT NOT NULL,
    practice_test_revision INTEGER NOT NULL,
    completed_at INTEGER NOT NULL,
    PRIMARY KEY (practice_test_code, practice_test_revision),
    CHECK (length(trim(practice_test_code)) > 0),
    CHECK (practice_test_revision > 0),
    CHECK (completed_at > 0)
  )
  ''',
];
