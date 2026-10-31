const universalCatalogueSchemaV9Statements = <String>[
  '''
  CREATE TABLE IF NOT EXISTS publication_snapshots (
    content_version INTEGER NOT NULL PRIMARY KEY,
    schema_version INTEGER NOT NULL,
    minimum_app_contract_version INTEGER NOT NULL,
    published_at INTEGER NOT NULL,
    checksum TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    CHECK (content_version > 0),
    CHECK (schema_version > 0),
    CHECK (minimum_app_contract_version > 0),
    CHECK (length(trim(checksum)) = 64)
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS vertical_section_reads (
    content_version INTEGER NOT NULL,
    code TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    icon_asset_id TEXT,
    sort_order INTEGER NOT NULL,
    active INTEGER NOT NULL,
    PRIMARY KEY (content_version, code),
    FOREIGN KEY (content_version)
      REFERENCES publication_snapshots(content_version)
      ON DELETE CASCADE,
    CHECK (length(trim(code)) > 0),
    CHECK (length(trim(title)) > 0),
    CHECK (description IS NULL OR length(trim(description)) > 0),
    CHECK (icon_asset_id IS NULL OR length(trim(icon_asset_id)) > 0),
    CHECK (sort_order >= 0),
    CHECK (active IN (0, 1))
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS learning_vertical_reads (
    content_version INTEGER NOT NULL,
    code TEXT NOT NULL,
    section_code TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    icon_asset_id TEXT NOT NULL,
    sort_order INTEGER NOT NULL,
    active INTEGER NOT NULL,
    PRIMARY KEY (content_version, code),
    FOREIGN KEY (content_version, section_code)
      REFERENCES vertical_section_reads(content_version, code)
      ON DELETE RESTRICT,
    CHECK (length(trim(code)) > 0),
    CHECK (length(trim(section_code)) > 0),
    CHECK (length(trim(title)) > 0),
    CHECK (length(trim(description)) > 0),
    CHECK (length(trim(icon_asset_id)) > 0),
    CHECK (sort_order >= 0),
    CHECK (active IN (0, 1))
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS learning_goal_reads (
    content_version INTEGER NOT NULL,
    code TEXT NOT NULL,
    vertical_code TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    sort_order INTEGER NOT NULL,
    active INTEGER NOT NULL,
    PRIMARY KEY (content_version, code),
    UNIQUE (content_version, vertical_code, code),
    FOREIGN KEY (content_version, vertical_code)
      REFERENCES learning_vertical_reads(content_version, code)
      ON DELETE RESTRICT,
    CHECK (length(trim(code)) > 0),
    CHECK (length(trim(vertical_code)) > 0),
    CHECK (length(trim(title)) > 0),
    CHECK (length(trim(description)) > 0),
    CHECK (sort_order >= 0),
    CHECK (active IN (0, 1))
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS learning_track_reads (
    content_version INTEGER NOT NULL,
    code TEXT NOT NULL,
    vertical_code TEXT NOT NULL,
    goal_code TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    level_code TEXT NOT NULL,
    career_track_code TEXT,
    sort_order INTEGER NOT NULL,
    active INTEGER NOT NULL,
    PRIMARY KEY (content_version, code),
    UNIQUE (content_version, vertical_code, code),
    FOREIGN KEY (content_version, vertical_code, goal_code)
      REFERENCES learning_goal_reads(content_version, vertical_code, code)
      ON DELETE RESTRICT,
    CHECK (length(trim(code)) > 0),
    CHECK (length(trim(vertical_code)) > 0),
    CHECK (length(trim(goal_code)) > 0),
    CHECK (length(trim(title)) > 0),
    CHECK (length(trim(description)) > 0),
    CHECK (length(trim(level_code)) > 0),
    CHECK (career_track_code IS NULL OR length(trim(career_track_code)) > 0),
    CHECK (sort_order >= 0),
    CHECK (active IN (0, 1))
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS learning_collection_reads (
    content_version INTEGER NOT NULL,
    code TEXT NOT NULL,
    vertical_code TEXT NOT NULL,
    track_code TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    sort_order INTEGER NOT NULL,
    active INTEGER NOT NULL,
    PRIMARY KEY (content_version, code),
    FOREIGN KEY (content_version, vertical_code, track_code)
      REFERENCES learning_track_reads(content_version, vertical_code, code)
      ON DELETE RESTRICT,
    CHECK (length(trim(code)) > 0),
    CHECK (length(trim(vertical_code)) > 0),
    CHECK (length(trim(track_code)) > 0),
    CHECK (length(trim(title)) > 0),
    CHECK (length(trim(description)) > 0),
    CHECK (sort_order >= 0),
    CHECK (active IN (0, 1))
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS learning_collection_member_reads (
    content_version INTEGER NOT NULL,
    collection_code TEXT NOT NULL,
    position INTEGER NOT NULL,
    member_type TEXT NOT NULL,
    content_code TEXT,
    content_type TEXT,
    content_revision INTEGER,
    content_checksum TEXT,
    practice_test_code TEXT,
    practice_test_revision INTEGER,
    practice_test_checksum TEXT,
    PRIMARY KEY (content_version, collection_code, position),
    FOREIGN KEY (content_version, collection_code)
      REFERENCES learning_collection_reads(content_version, code)
      ON DELETE CASCADE,
    CHECK (position >= 0),
    CHECK (member_type IN ('CONTENT', 'PRACTICE_TEST')),
    CHECK (
      (member_type = 'CONTENT'
        AND content_code IS NOT NULL
        AND content_type IS NOT NULL
        AND content_revision IS NOT NULL
        AND content_revision > 0
        AND content_checksum IS NOT NULL
        AND length(trim(content_checksum)) = 64
        AND practice_test_code IS NULL
        AND practice_test_revision IS NULL
        AND practice_test_checksum IS NULL)
      OR
      (member_type = 'PRACTICE_TEST'
        AND practice_test_code IS NOT NULL
        AND practice_test_revision IS NOT NULL
        AND practice_test_revision > 0
        AND practice_test_checksum IS NOT NULL
        AND length(trim(practice_test_checksum)) = 64
        AND content_code IS NULL
        AND content_type IS NULL
        AND content_revision IS NULL
        AND content_checksum IS NULL)
    )
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS vertical_presentation_reads (
    content_version INTEGER NOT NULL PRIMARY KEY,
    mode TEXT NOT NULL,
    show_featured INTEGER NOT NULL,
    show_see_all INTEGER NOT NULL,
    featured_section_code TEXT,
    FOREIGN KEY (content_version)
      REFERENCES publication_snapshots(content_version)
      ON DELETE CASCADE,
    FOREIGN KEY (content_version, featured_section_code)
      REFERENCES vertical_section_reads(content_version, code)
      ON DELETE RESTRICT,
    CHECK (mode IN ('CAROUSEL', 'SHELVES', 'GRID')),
    CHECK (show_featured IN (0, 1)),
    CHECK (show_see_all IN (0, 1)),
    CHECK (
      (show_featured = 1 AND featured_section_code IS NOT NULL)
      OR (show_featured = 0)
    )
  )
  ''',
  'CREATE INDEX IF NOT EXISTS idx_vertical_sections_snapshot_order ON vertical_section_reads(content_version, sort_order, code)',
  'CREATE INDEX IF NOT EXISTS idx_verticals_snapshot_section_order ON learning_vertical_reads(content_version, section_code, sort_order, code)',
  'CREATE INDEX IF NOT EXISTS idx_goals_snapshot_vertical_order ON learning_goal_reads(content_version, vertical_code, sort_order, code)',
  'CREATE INDEX IF NOT EXISTS idx_tracks_snapshot_goal_order ON learning_track_reads(content_version, goal_code, sort_order, code)',
  'CREATE INDEX IF NOT EXISTS idx_collections_snapshot_track_order ON learning_collection_reads(content_version, track_code, sort_order, code)',
];
