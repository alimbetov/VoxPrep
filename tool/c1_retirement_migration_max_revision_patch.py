from pathlib import Path

path = Path('mobile/careerspeak_app/lib/data/local/database/careerspeak_database.dart')
text = path.read_text()

old_sync = '''        await customStatement('''
          INSERT OR IGNORE INTO content_retirements (
            content_code,
            content_type,
            retired_revision,
            reason,
            source_content_version,
            retired_at
          )
          SELECT
            st.content_code,
            st.content_type,
            COALESCE(NULLIF(st.revision, 0), 1),
            st.reason,
            COALESCE(
              NULLIF(sr.target_content_version, 0),
              NULLIF((
                SELECT current_content_version
                FROM content_manifest_states
                WHERE id = 1
              ), 0),
              1
            ),
            COALESCE(st.applied_at, sr.updated_at)
          FROM sync_tombstones st
          INNER JOIN sync_runs sr ON sr.run_id = st.run_id
          WHERE st.state = 'APPLIED'
        ''');
'''
new_sync = '''        await customStatement('''
          INSERT OR IGNORE INTO content_retirements (
            content_code,
            content_type,
            retired_revision,
            reason,
            source_content_version,
            retired_at
          )
          SELECT
            ranked.content_code,
            ranked.content_type,
            ranked.retired_revision,
            ranked.reason,
            ranked.source_content_version,
            ranked.retired_at
          FROM (
            SELECT
              st.content_code AS content_code,
              st.content_type AS content_type,
              COALESCE(NULLIF(st.revision, 0), 1) AS retired_revision,
              st.reason AS reason,
              COALESCE(
                NULLIF(sr.target_content_version, 0),
                NULLIF((
                  SELECT current_content_version
                  FROM content_manifest_states
                  WHERE id = 1
                ), 0),
                1
              ) AS source_content_version,
              COALESCE(st.applied_at, sr.updated_at) AS retired_at,
              ROW_NUMBER() OVER (
                PARTITION BY st.content_code, st.content_type
                ORDER BY
                  COALESCE(NULLIF(st.revision, 0), 1) DESC,
                  COALESCE(st.applied_at, sr.updated_at) DESC
              ) AS retirement_rank
            FROM sync_tombstones st
            INNER JOIN sync_runs sr ON sr.run_id = st.run_id
            WHERE st.state = 'APPLIED'
          ) ranked
          WHERE ranked.retirement_rank = 1
        ''');
'''
if new_sync not in text:
    if old_sync not in text:
        raise SystemExit('missing sync-tombstone migration selection')
    text = text.replace(old_sync, new_sync, 1)

old_local = '''        await customStatement('''
          INSERT OR IGNORE INTO content_retirements (
            content_code,
            content_type,
            retired_revision,
            reason,
            source_content_version,
            retired_at
          )
          SELECT
            local.content_code,
            local.content_type,
            local.revision,
            'LEGACY_TOMBSTONE',
            COALESCE(
              NULLIF((
                SELECT current_content_version
                FROM content_manifest_states
                WHERE id = 1
              ), 0),
              1
            ),
            local.created_at
          FROM local_content_records local
          WHERE local.snapshot_state = 'TOMBSTONED'
        ''');
'''
new_local = '''        await customStatement('''
          INSERT OR IGNORE INTO content_retirements (
            content_code,
            content_type,
            retired_revision,
            reason,
            source_content_version,
            retired_at
          )
          SELECT
            local.content_code,
            local.content_type,
            MAX(local.revision),
            'LEGACY_TOMBSTONE',
            COALESCE(
              NULLIF((
                SELECT current_content_version
                FROM content_manifest_states
                WHERE id = 1
              ), 0),
              1
            ),
            MAX(local.created_at)
          FROM local_content_records local
          WHERE local.snapshot_state = 'TOMBSTONED'
          GROUP BY local.content_code, local.content_type
        ''');
'''
if new_local not in text:
    if old_local not in text:
        raise SystemExit('missing local-tombstone migration selection')
    text = text.replace(old_local, new_local, 1)

path.write_text(text)
