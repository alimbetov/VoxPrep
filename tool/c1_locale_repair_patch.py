from pathlib import Path

path = Path('mobile/careerspeak_app/lib/data/local/drift_sync_journal.dart')
text = path.read_text()
old = """        if (row.variantKey != 'canonical') continue;

        final refs =
"""
new = """        if (row.variantKey != 'canonical') {
          final localizationRefs =
              await (_database.select(_database.packLocalizationRefs)..where(
                    (ref) =>
                        ref.packCode.equals(row.packCode) &
                        ref.variantKey.equals(row.variantKey) &
                        ref.packRevision.equals(row.revision),
                  ))
                  .get();
          for (final ref in localizationRefs) {
            final payload =
                await (_database.select(_database.localizedContentReads)..where(
                      (content) =>
                          content.contentCode.equals(ref.contentCode) &
                          content.contentType.equals(ref.contentType) &
                          content.contentRevision.equals(ref.contentRevision) &
                          content.locale.equals(ref.locale) &
                          content.localizationRevision.equals(
                            ref.localizationRevision,
                          ),
                    ))
                    .getSingleOrNull();
            if (payload == null || payload.checksum != ref.checksum) {
              contentPayloadRepairPacks.add(identity);
              break;
            }
          }
          continue;
        }

        final refs =
"""
if new not in text:
    if old not in text:
        raise SystemExit('missing locale repair journal anchor')
    path.write_text(text.replace(old, new, 1))
