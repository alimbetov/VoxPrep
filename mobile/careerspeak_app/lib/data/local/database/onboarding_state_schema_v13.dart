const onboardingStateSchemaV13Statements = <String>[
  '''
  CREATE TABLE IF NOT EXISTS onboarding_state (
    id INTEGER PRIMARY KEY NOT NULL CHECK (id = 1),
    completed INTEGER NOT NULL DEFAULT 0 CHECK (completed IN (0, 1)),
    generation INTEGER NOT NULL DEFAULT 0 CHECK (generation >= 0),
    updated_at INTEGER NOT NULL
  )
  ''',
  '''
  INSERT OR IGNORE INTO onboarding_state (
    id,
    completed,
    generation,
    updated_at
  ) VALUES (1, 0, 0, 0)
  ''',
];
