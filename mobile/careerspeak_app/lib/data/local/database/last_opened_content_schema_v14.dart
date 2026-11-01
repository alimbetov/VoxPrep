const lastOpenedContentSchemaV14Statements = <String>[
  '''
  CREATE TABLE IF NOT EXISTS learner_last_opened_content (
    id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1),
    content_code TEXT NOT NULL CHECK (length(trim(content_code)) > 0),
    content_type TEXT NOT NULL CHECK (length(trim(content_type)) > 0),
    content_revision INTEGER NOT NULL CHECK (content_revision > 0),
    opened_at INTEGER NOT NULL CHECK (opened_at > 0)
  )
  ''',
];
