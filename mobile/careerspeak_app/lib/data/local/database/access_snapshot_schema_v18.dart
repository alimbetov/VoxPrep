const accessSnapshotSchemaV18Statements = <String>[
  '''
  CREATE TABLE IF NOT EXISTS learner_access_snapshot (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    access_level TEXT NOT NULL,
    verified_at INTEGER NOT NULL,
    source TEXT NOT NULL,
    updated_at INTEGER NOT NULL,
    CHECK (access_level IN ('FREE', 'FULL')),
    CHECK (source IN ('BACKEND_VERIFIED', 'STORE_RESTORE'))
  )
  ''',
];
