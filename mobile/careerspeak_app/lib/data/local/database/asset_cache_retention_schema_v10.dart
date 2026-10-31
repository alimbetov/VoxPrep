const assetCacheRetentionSchemaV10Statements = <String>[
  '''
  CREATE TABLE IF NOT EXISTS asset_cache_retention (
    asset_id TEXT NOT NULL PRIMARY KEY,
    checksum_sha256 TEXT NOT NULL,
    delivery_key TEXT NOT NULL,
    size_bytes INTEGER NOT NULL,
    media_type TEXT NOT NULL,
    required_offline INTEGER NOT NULL,
    retention_class TEXT NOT NULL,
    cached_at INTEGER NOT NULL,
    last_accessed_at INTEGER NOT NULL,
    CHECK (length(trim(asset_id)) > 0),
    CHECK (length(trim(checksum_sha256)) = 64),
    CHECK (length(trim(delivery_key)) > 0),
    CHECK (size_bytes > 0),
    CHECK (length(trim(media_type)) > 0),
    CHECK (required_offline IN (0, 1)),
    CHECK (retention_class IN ('AUTO_CACHE', 'EXPLICIT_DOWNLOAD', 'PINNED'))
  )
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_asset_cache_retention_cleanup
  ON asset_cache_retention(retention_class, media_type, last_accessed_at)
  ''',
];
