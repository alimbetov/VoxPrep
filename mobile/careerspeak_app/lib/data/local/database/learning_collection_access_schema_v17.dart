const learningCollectionAccessSchemaV17Statements = <String>[
  '''
  CREATE TABLE IF NOT EXISTS learning_collection_access_reads (
    content_version INTEGER NOT NULL,
    collection_code TEXT NOT NULL,
    access_level TEXT NOT NULL,
    PRIMARY KEY (content_version, collection_code),
    FOREIGN KEY (content_version, collection_code)
      REFERENCES learning_collection_reads(content_version, code)
      ON DELETE CASCADE,
    CHECK (access_level IN ('FREE', 'FULL'))
  )
  ''',
  'CREATE INDEX IF NOT EXISTS idx_collection_access_level ON learning_collection_access_reads(content_version, access_level, collection_code)',
];
