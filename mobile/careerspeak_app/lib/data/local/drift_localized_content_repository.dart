import 'package:drift/drift.dart';

import '../../application/content_delivery/locale_fallback.dart';
import '../../application/content_delivery/localized_content_resolution.dart';
import '../../application/ports/localized_content_repository.dart';
import '../../application/result/result.dart';
import '../../domain/content_identity.dart';
import 'content_type_storage.dart';
import 'database/careerspeak_database.dart';

final class DriftLocalizedContentRepository
    implements LocalizedContentRepository {
  const DriftLocalizedContentRepository(this._database);

  final CareerSpeakDatabase _database;

  @override
  Future<Result<ResolvedLocalizedContent?>> resolve({
    required ContentIdentity identity,
    required int contentRevision,
    required String requestedLocale,
  }) async {
    if (contentRevision < 1) {
      return const FailureResult<ResolvedLocalizedContent?>(
        ApplicationFailure(
          code: 'LOCALIZED_CONTENT_REQUEST_INVALID',
          message: 'Content revision must be positive.',
        ),
      );
    }

    final LocaleFallbackPlan fallback;
    try {
      fallback = LocaleFallbackPlan(requestedLocale);
    } on FormatException {
      return FailureResult<ResolvedLocalizedContent?>(
        ApplicationFailure(
          code: 'LOCALE_INVALID',
          message: 'Requested localization locale is invalid.',
          details: <String, Object?>{'requestedLocale': requestedLocale},
        ),
      );
    }

    try {
      final canonical = await _readCanonical(
        identity: identity,
        contentRevision: contentRevision,
      );
      if (canonical == null) {
        return const Success<ResolvedLocalizedContent?>(null);
      }

      final matches = <_LocalizedMatch>[];
      for (final candidate in fallback.localizedCandidates) {
        final layer = await _readLocalization(
          identity: identity,
          contentRevision: contentRevision,
          locale: candidate.locale,
        );
        if (layer != null) {
          matches.add(_LocalizedMatch(candidate: candidate, layer: layer));
        }
      }

      var title = canonical.title;
      var subtitle = canonical.subtitle;
      var description = canonical.description;
      String? translation;
      String? hint;
      String? explanation;

      for (final match in matches.reversed) {
        final layer = match.layer;
        title = layer.title ?? title;
        subtitle = layer.subtitle ?? subtitle;
        description = layer.description ?? description;
        translation = layer.translation ?? translation;
        hint = layer.hint ?? hint;
        explanation = layer.explanation ?? explanation;
      }

      final primary = matches.isEmpty ? null : matches.first.candidate;
      return Success<ResolvedLocalizedContent?>(
        ResolvedLocalizedContent(
          identity: identity,
          contentRevision: contentRevision,
          requestedLocale: fallback.requestedLocale,
          resolvedLocale:
              primary?.locale ?? LocaleFallbackPlan.canonicalEnglishLocale,
          fallbackKind:
              primary?.kind ?? LocaleFallbackKind.canonicalEnglish,
          matchedLocalizationLocales: List<String>.unmodifiable(
            matches.map((match) => match.candidate.locale),
          ),
          title: title,
          subtitle: subtitle,
          description: description,
          translation: translation,
          hint: hint,
          explanation: explanation,
        ),
      );
    } on _LocalizedReadInvariant catch (error) {
      return FailureResult<ResolvedLocalizedContent?>(
        ApplicationFailure(
          code: 'LOCALIZED_CONTENT_READ_MODEL_INVALID',
          message: 'The local localized content read model is inconsistent.',
          details: <String, Object?>{'reason': error.reason},
        ),
      );
    } on Object catch (error) {
      return FailureResult<ResolvedLocalizedContent?>(
        ApplicationFailure(
          code: 'LOCALIZED_CONTENT_READ_FAILED',
          message: 'Localized content could not be read from local storage.',
          retryable: true,
          details: <String, Object?>{'cause': error.runtimeType.toString()},
        ),
      );
    }
  }

  Future<_CanonicalProjection?> _readCanonical({
    required ContentIdentity identity,
    required int contentRevision,
  }) async {
    final rows = await _database
        .customSelect(
          _canonicalSql,
          variables: <Variable<Object>>[
            Variable<String>(identity.code),
            Variable<String>(contentTypeToStorage(identity.type)),
            Variable<int>(contentRevision),
          ],
          readsFrom: <ResultSetImplementation>{
            _database.localContentRecords,
            _database.contentCatalogReads,
          },
        )
        .get();

    if (rows.isEmpty) {
      return null;
    }
    if (rows.length != 1) {
      throw const _LocalizedReadInvariant(
        'more than one CURRENT canonical row matches the requested revision',
      );
    }

    final row = rows.single;
    final metadataChecksum = row.read<String>('metadata_checksum');
    final payloadCode = row.readNullable<String>('payload_content_code');
    final payloadType = row.readNullable<String>('payload_content_type');
    final payloadRevision = row.readNullable<int>('payload_revision');
    final payloadChecksum = row.readNullable<String>('payload_checksum');
    final title = row.readNullable<String>('title');
    final subtitle = row.readNullable<String>('subtitle');
    final description = row.readNullable<String>('description');

    if (payloadCode == null ||
        payloadType == null ||
        payloadRevision == null ||
        payloadChecksum == null ||
        title == null ||
        subtitle == null ||
        description == null) {
      throw const _LocalizedReadInvariant(
        'CURRENT canonical metadata has no complete learner payload',
      );
    }

    if (payloadCode != identity.code ||
        payloadType != contentTypeToStorage(identity.type) ||
        payloadRevision != contentRevision ||
        payloadChecksum != metadataChecksum) {
      throw const _LocalizedReadInvariant(
        'CURRENT canonical metadata and payload identity/checksum differ',
      );
    }

    return _CanonicalProjection(
      title: title,
      subtitle: subtitle,
      description: description,
    );
  }

  Future<_LocalizedLayer?> _readLocalization({
    required ContentIdentity identity,
    required int contentRevision,
    required String locale,
  }) async {
    final rows = await _database
        .customSelect(
          _localizedSql,
          variables: <Variable<Object>>[
            Variable<String>('locale:$locale'),
            Variable<String>(identity.code),
            Variable<String>(contentTypeToStorage(identity.type)),
            Variable<int>(contentRevision),
            Variable<String>(locale),
          ],
          readsFrom: <ResultSetImplementation>{
            _database.contentPackRevisions,
            _database.packLocalizationRefs,
            _database.localizedContentReads,
          },
        )
        .get();

    if (rows.isEmpty) {
      return null;
    }
    if (rows.length != 1) {
      throw _LocalizedReadInvariant(
        'more than one immutable localization is CURRENT for $locale',
      );
    }

    final row = rows.single;
    final refChecksum = row.read<String>('ref_checksum');
    final payloadChecksum = row.read<String>('payload_checksum');
    if (refChecksum != payloadChecksum) {
      throw _LocalizedReadInvariant(
        'CURRENT localization checksum differs from its pack reference for $locale',
      );
    }

    return _LocalizedLayer(
      title: row.readNullable<String>('title'),
      subtitle: row.readNullable<String>('subtitle'),
      description: row.readNullable<String>('description'),
      translation: row.readNullable<String>('translation'),
      hint: row.readNullable<String>('hint'),
      explanation: row.readNullable<String>('explanation'),
    );
  }
}

final class _CanonicalProjection {
  const _CanonicalProjection({
    required this.title,
    required this.subtitle,
    required this.description,
  });

  final String title;
  final String subtitle;
  final String description;
}

final class _LocalizedLayer {
  const _LocalizedLayer({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.translation,
    required this.hint,
    required this.explanation,
  });

  final String? title;
  final String? subtitle;
  final String? description;
  final String? translation;
  final String? hint;
  final String? explanation;
}

final class _LocalizedMatch {
  const _LocalizedMatch({required this.candidate, required this.layer});

  final LocaleFallbackCandidate candidate;
  final _LocalizedLayer layer;
}

final class _LocalizedReadInvariant implements Exception {
  const _LocalizedReadInvariant(this.reason);

  final String reason;
}

const _canonicalSql = '''
SELECT
  r.checksum AS metadata_checksum,
  c.content_code AS payload_content_code,
  c.content_type AS payload_content_type,
  c.revision AS payload_revision,
  c.checksum AS payload_checksum,
  c.title,
  c.subtitle,
  c.description
FROM local_content_records r
LEFT JOIN content_catalog_reads c
  ON c.content_code = r.content_code
 AND c.content_type = r.content_type
 AND c.revision = r.revision
WHERE r.snapshot_state = 'CURRENT'
  AND r.content_code = ?
  AND r.content_type = ?
  AND r.revision = ?''';

const _localizedSql = '''
SELECT DISTINCT
  p.checksum AS ref_checksum,
  l.checksum AS payload_checksum,
  l.title,
  l.subtitle,
  l.description,
  l.translation,
  l.hint,
  l.explanation
FROM pack_localization_refs p
JOIN content_pack_revisions pack
  ON pack.pack_code = p.pack_code
 AND pack.variant_key = p.variant_key
 AND pack.revision = p.pack_revision
JOIN localized_content_reads l
  ON l.content_code = p.content_code
 AND l.content_type = p.content_type
 AND l.content_revision = p.content_revision
 AND l.locale = p.locale
 AND l.localization_revision = p.localization_revision
WHERE pack.state = 'CURRENT'
  AND p.variant_key = ?
  AND p.content_code = ?
  AND p.content_type = ?
  AND p.content_revision = ?
  AND p.locale = ?''';
