import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../application/ports/content_repository.dart';
import '../../application/query/content_query.dart';
import '../../application/query/page.dart';
import '../../application/result/result.dart';
import '../../domain/content_identity.dart';
import '../../domain/content_item.dart';
import 'content_type_storage.dart';
import 'database/careerspeak_database.dart';

final class DriftContentRepository implements ContentRepository {
  const DriftContentRepository(this._database);

  final CareerSpeakDatabase _database;

  @override
  Stream<Result<Page<ContentItem>>> watchContent(ContentQuery query) {
    try {
      final cursor = query.page.cursor == null
          ? null
          : _ContentCursor.decode(query.page.cursor!);
      return _watchContent(query, cursor);
    } on _ContentCursorViolation catch (error) {
      return Stream<Result<Page<ContentItem>>>.value(
        FailureResult<Page<ContentItem>>(
          ApplicationFailure(
            code: 'INVALID_CONTENT_CURSOR',
            message: 'The content page cursor is invalid.',
            details: <String, Object?>{'reason': error.reason},
          ),
        ),
      );
    }
  }

  Stream<Result<Page<ContentItem>>> _watchContent(
    ContentQuery query,
    _ContentCursor? cursor,
  ) async* {
    final select = _buildCatalogSelect(query, cursor);

    try {
      await for (final rows in select.watch()) {
        try {
          yield Success<Page<ContentItem>>(
            _pageFromRows(rows, query.page.limit),
          );
        } on _ContentReadInvariant catch (error) {
          yield FailureResult<Page<ContentItem>>(_invalidReadModel(error));
        } on Object catch (error) {
          yield FailureResult<Page<ContentItem>>(_readFailure(error));
        }
      }
    } on Object catch (error) {
      yield FailureResult<Page<ContentItem>>(_readFailure(error));
    }
  }

  @override
  Future<Result<ContentItem?>> getByIdentity(ContentIdentity identity) async {
    try {
      final rows = await _database
          .customSelect(
            _identitySql,
            variables: <Variable<Object>>[
              Variable<String>(identity.code),
              Variable<String>(contentTypeToStorage(identity.type)),
            ],
            readsFrom: _publicationReadDependencies,
          )
          .get();

      if (rows.isEmpty) {
        return const Success<ContentItem?>(null);
      }
      if (rows.length != 1) {
        return FailureResult<ContentItem?>(
          _invalidReadModel(
            const _ContentReadInvariant(
              'more than one CURRENT revision exists for one content identity',
            ),
          ),
        );
      }

      final projection = _projection(rows.single);
      if (projection.item.code != identity.code ||
          projection.item.type != identity.type) {
        return FailureResult<ContentItem?>(
          _invalidReadModel(
            const _ContentReadInvariant(
              'the CURRENT projection does not match the requested identity',
            ),
          ),
        );
      }
      return Success<ContentItem?>(projection.item);
    } on _ContentReadInvariant catch (error) {
      return FailureResult<ContentItem?>(_invalidReadModel(error));
    } on Object catch (error) {
      return FailureResult<ContentItem?>(_readFailure(error));
    }
  }

  Selectable<QueryRow> _buildCatalogSelect(
    ContentQuery query,
    _ContentCursor? cursor,
  ) {
    final sql = StringBuffer(_catalogSelectPrefix);
    final variables = <Variable<Object>>[];

    final search = query.search?.trim().toLowerCase();
    if (search != null && search.isNotEmpty) {
      sql.write(
        " AND lower(c.title || ' ' || c.subtitle || ' ' || c.description) LIKE ? ESCAPE '\\'",
      );
      variables.add(Variable<String>('%${_escapeLike(search)}%'));
    }

    if (query.types.isNotEmpty) {
      final orderedTypes = query.types.toList(growable: false)
        ..sort((left, right) => left.name.compareTo(right.name));
      sql.write(
        ' AND r.content_type IN (${List.filled(orderedTypes.length, '?').join(', ')})',
      );
      variables.addAll(
        orderedTypes.map<Variable<Object>>(
          (type) => Variable<String>(contentTypeToStorage(type)),
        ),
      );
    }

    if (query.category != null) {
      sql.write(' AND c.category = ?');
      variables.add(Variable<String>(query.category!));
    }
    if (query.level != null) {
      sql.write(' AND c.level = ?');
      variables.add(Variable<String>(query.level!));
    }

    if (cursor != null) {
      sql.write('''
 AND (
   coalesce(r.sort_order, $_nullSortOrder) > ?
   OR (
     coalesce(r.sort_order, $_nullSortOrder) = ?
     AND r.content_type > ?
   )
   OR (
     coalesce(r.sort_order, $_nullSortOrder) = ?
     AND r.content_type = ?
     AND r.content_code > ?
   )
 )''');
      variables
        ..add(Variable<int>(cursor.sortOrder))
        ..add(Variable<int>(cursor.sortOrder))
        ..add(Variable<String>(cursor.contentType))
        ..add(Variable<int>(cursor.sortOrder))
        ..add(Variable<String>(cursor.contentType))
        ..add(Variable<String>(cursor.contentCode));
    }

    sql.write('''
 ORDER BY
   coalesce(r.sort_order, $_nullSortOrder),
   r.content_type,
   r.content_code
 LIMIT ?''');
    variables.add(Variable<int>(query.page.limit + 1));

    return _database.customSelect(
      sql.toString(),
      variables: variables,
      readsFrom: _publicationReadDependencies,
    );
  }

  Set<ResultSetImplementation> get _publicationReadDependencies =>
      <ResultSetImplementation>{
        _database.localContentRecords,
        _database.contentCatalogReads,
        _database.contentManifestStates,
        _database.contentPackRevisions,
        _database.packContentRefs,
      };

  Page<ContentItem> _pageFromRows(List<QueryRow> rows, int limit) {
    final projections = rows.map(_projection).toList(growable: false);
    final hasMore = projections.length > limit;
    final pageItems = hasMore ? projections.sublist(0, limit) : projections;

    return Page<ContentItem>(
      items: pageItems
          .map((projection) => projection.item)
          .toList(growable: false),
      hasMore: hasMore,
      nextCursor: hasMore && pageItems.isNotEmpty
          ? pageItems.last.cursor.encode()
          : null,
    );
  }

  _ContentProjection _projection(QueryRow row) {
    final currentCount = row.read<int>('current_count');
    if (currentCount != 1) {
      throw const _ContentReadInvariant(
        'more than one CURRENT revision exists for one content identity',
      );
    }

    final code = row.read<String>('content_code');
    final typeName = row.read<String>('content_type');
    final revision = row.read<int>('revision');
    final metadataChecksum = row.read<String>('metadata_checksum');

    final payloadCode = row.readNullable<String>('payload_content_code');
    final payloadType = row.readNullable<String>('payload_content_type');
    final payloadRevision = row.readNullable<int>('payload_revision');
    final payloadChecksum = row.readNullable<String>('payload_checksum');

    if (payloadCode == null ||
        payloadType == null ||
        payloadRevision == null ||
        payloadChecksum == null) {
      throw const _ContentReadInvariant(
        'a CURRENT metadata revision has no matching learner payload',
      );
    }
    if (payloadCode != code ||
        payloadType != typeName ||
        payloadRevision != revision ||
        payloadChecksum != metadataChecksum) {
      throw const _ContentReadInvariant(
        'CURRENT metadata and learner payload identity/checksum differ',
      );
    }

    final type = _contentType(typeName);
    final title = row.readNullable<String>('title');
    final subtitle = row.readNullable<String>('subtitle');
    final description = row.readNullable<String>('description');
    final category = row.readNullable<String>('category');
    final level = row.readNullable<String>('level');
    final minutes = row.readNullable<int>('minutes');
    final hasAudio = row.readNullable<int>('has_audio');

    if (title == null ||
        subtitle == null ||
        description == null ||
        category == null ||
        level == null ||
        minutes == null ||
        hasAudio == null) {
      throw const _ContentReadInvariant(
        'a CURRENT learner payload is incomplete',
      );
    }

    final sortOrder = row.readNullable<int>('sort_order') ?? _nullSortOrder;
    final item = ContentItem(
      code: code,
      type: type,
      title: title,
      subtitle: subtitle,
      description: description,
      category: category,
      level: level,
      minutes: minutes,
      revision: revision,
      hasAudio: hasAudio != 0,
    );

    return _ContentProjection(
      item,
      _ContentCursor(
        sortOrder: sortOrder,
        contentType: typeName,
        contentCode: code,
      ),
    );
  }

  ContentType _contentType(String value) {
    try {
      return contentTypeFromStorage(value);
    } on FormatException {
      throw _ContentReadInvariant('unsupported stored content type: $value');
    }
  }

  ApplicationFailure _invalidReadModel(_ContentReadInvariant error) {
    return ApplicationFailure(
      code: 'CONTENT_READ_MODEL_INVALID',
      message: 'The local content read model is inconsistent.',
      details: <String, Object?>{'reason': error.reason},
    );
  }

  ApplicationFailure _readFailure(Object error) {
    return ApplicationFailure(
      code: 'CONTENT_READ_FAILED',
      message: 'The local content catalog could not be read.',
      retryable: true,
      details: <String, Object?>{'cause': error.runtimeType.toString()},
    );
  }
}

final class _ContentProjection {
  const _ContentProjection(this.item, this.cursor);

  final ContentItem item;
  final _ContentCursor cursor;
}

final class _ContentCursor {
  const _ContentCursor({
    required this.sortOrder,
    required this.contentType,
    required this.contentCode,
  });

  factory _ContentCursor.decode(String encoded) {
    if (encoded.trim().isEmpty) {
      throw const _ContentCursorViolation('cursor must not be blank');
    }

    try {
      final decoded = utf8.decode(
        base64Url.decode(base64Url.normalize(encoded)),
      );
      final value = jsonDecode(decoded);
      if (value is! Map<String, dynamic>) {
        throw const _ContentCursorViolation('cursor payload must be an object');
      }
      final sortOrder = value['sortOrder'];
      final contentType = value['contentType'];
      final contentCode = value['contentCode'];
      if (sortOrder is! int ||
          contentType is! String ||
          contentType.isEmpty ||
          contentCode is! String ||
          contentCode.isEmpty) {
        throw const _ContentCursorViolation('cursor payload is incomplete');
      }
      return _ContentCursor(
        sortOrder: sortOrder,
        contentType: contentType,
        contentCode: contentCode,
      );
    } on _ContentCursorViolation {
      rethrow;
    } on Object {
      throw const _ContentCursorViolation('cursor encoding is invalid');
    }
  }

  final int sortOrder;
  final String contentType;
  final String contentCode;

  String encode() {
    final json = jsonEncode(<String, Object>{
      'sortOrder': sortOrder,
      'contentType': contentType,
      'contentCode': contentCode,
    });
    return base64Url.encode(utf8.encode(json));
  }
}

final class _ContentCursorViolation implements Exception {
  const _ContentCursorViolation(this.reason);

  final String reason;
}

final class _ContentReadInvariant implements Exception {
  const _ContentReadInvariant(this.reason);

  final String reason;
}

String _escapeLike(String value) {
  return value
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');
}

const _nullSortOrder = 2147483647;

const _snapshotVisibilityPredicate = '''
  l.snapshot_state = 'CURRENT'
  AND (
    NOT EXISTS (
      SELECT 1
      FROM content_manifest_states legacy_guard
      WHERE legacy_guard.id = 1
    )
    OR EXISTS (
      SELECT 1
      FROM content_manifest_states root
      INNER JOIN content_pack_revisions pack
        ON pack.source_content_version = root.current_content_version
       AND pack.state = 'CURRENT'
      INNER JOIN pack_content_refs member
        ON member.pack_code = pack.pack_code
       AND member.variant_key = pack.variant_key
       AND member.pack_revision = pack.revision
      WHERE root.id = 1
        AND member.content_code = l.content_code
        AND member.content_type = l.content_type
        AND member.content_revision = l.revision
    )
  )''';

const _catalogSelectPrefix =
    '''
WITH current_content AS (
  SELECT
    l.*,
    count(*) OVER (
      PARTITION BY l.content_code, l.content_type
    ) AS current_count
  FROM local_content_records l
  WHERE $_snapshotVisibilityPredicate
)
SELECT
  r.content_code,
  r.content_type,
  r.revision,
  r.checksum AS metadata_checksum,
  r.sort_order,
  r.current_count,
  c.content_code AS payload_content_code,
  c.content_type AS payload_content_type,
  c.revision AS payload_revision,
  c.checksum AS payload_checksum,
  c.title,
  c.subtitle,
  c.description,
  c.category,
  c.level,
  c.minutes,
  c.has_audio
FROM current_content r
LEFT JOIN content_catalog_reads c
  ON c.content_code = r.content_code
 AND c.content_type = r.content_type
 AND c.revision = r.revision
WHERE 1 = 1''';

const _identitySql =
    '''
WITH current_content AS (
  SELECT
    l.*,
    count(*) OVER (
      PARTITION BY l.content_code, l.content_type
    ) AS current_count
  FROM local_content_records l
  WHERE $_snapshotVisibilityPredicate
)
SELECT
  r.content_code,
  r.content_type,
  r.revision,
  r.checksum AS metadata_checksum,
  r.sort_order,
  r.current_count,
  c.content_code AS payload_content_code,
  c.content_type AS payload_content_type,
  c.revision AS payload_revision,
  c.checksum AS payload_checksum,
  c.title,
  c.subtitle,
  c.description,
  c.category,
  c.level,
  c.minutes,
  c.has_audio
FROM current_content r
LEFT JOIN content_catalog_reads c
  ON c.content_code = r.content_code
 AND c.content_type = r.content_type
 AND c.revision = r.revision
WHERE r.content_code = ?
  AND r.content_type = ?
ORDER BY r.revision DESC''';
