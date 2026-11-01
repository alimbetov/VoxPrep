const learnerSelectionSchemaV12Statements = <String>[
  '''
  CREATE TABLE IF NOT EXISTS learner_selection (
    id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1),
    selected_goal_code TEXT NULL,
    selected_track_code TEXT NULL,
    self_assessed_level_code TEXT NULL,
    level_decision_made INTEGER NOT NULL DEFAULT 0 CHECK (level_decision_made IN (0, 1)),
    generation INTEGER NOT NULL DEFAULT 0 CHECK (generation >= 0),
    updated_at INTEGER NOT NULL,
    CHECK (selected_track_code IS NULL OR selected_goal_code IS NOT NULL),
    CHECK (self_assessed_level_code IS NULL OR level_decision_made = 1)
  )
  ''',
  '''
  INSERT OR IGNORE INTO learner_selection (
    id,
    selected_goal_code,
    selected_track_code,
    self_assessed_level_code,
    level_decision_made,
    generation,
    updated_at
  ) VALUES (1, NULL, NULL, NULL, 0, 0, 0)
  ''',
];
