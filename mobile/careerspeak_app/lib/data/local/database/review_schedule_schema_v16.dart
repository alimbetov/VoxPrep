const reviewScheduleSchemaV16Statements = <String>[
  '''
  CREATE TABLE IF NOT EXISTS content_review_states (
    content_code TEXT NOT NULL,
    content_type TEXT NOT NULL,
    next_review_at INTEGER NOT NULL,
    review_stage INTEGER NOT NULL DEFAULT 0,
    last_review_outcome TEXT NULL,
    updated_at INTEGER NOT NULL,
    PRIMARY KEY (content_code, content_type),
    CHECK (length(trim(content_code)) > 0),
    CHECK (length(trim(content_type)) > 0),
    CHECK (next_review_at > 0),
    CHECK (review_stage >= 0),
    CHECK (
      last_review_outcome IS NULL OR
      last_review_outcome IN ('incorrect', 'hard', 'correct', 'known')
    ),
    CHECK (updated_at > 0)
  )
  ''',
];
