import 'dart:convert';

import 'package:drift/drift.dart';

import '../../application/content_delivery/content_payload.dart';
import '../../application/content_delivery/typed_content_body.dart';
import '../../application/result/result.dart';
import '../../domain/content_item.dart';
import '../remote/content_payload_decoder.dart';
import 'content_type_storage.dart';
import 'database/careerspeak_database.dart';

/// Exact typed body already persisted by the publication sync executor.
///
/// The caller must first resolve the content through the entitlement-aware
/// ContentRepository. Never use this class to discover locked content.
final class DriftTypedContentReader {
  const DriftTypedContentReader(this._database);

  final CareerSpeakDatabase _database;

  Future<TypedContentBody?> getForVisible(ContentItem item) async {
    final rows = await _database
        .customSelect(
          '''
      SELECT c.checksum, c.title, c.subtitle, c.description,
             c.category, c.level, c.minutes, c.has_audio,
             t.category_code, t.level_code, t.skill_codes_json,
             t.body_kind, t.body_json, t.checksum AS typed_checksum
      FROM content_catalog_reads c
      JOIN typed_content_reads t
        ON t.content_code = c.content_code
       AND t.content_type = c.content_type
       AND t.revision = c.revision
      WHERE c.content_code = ? AND c.content_type = ?
        AND c.revision = ?
      ''',
          variables: <Variable<Object>>[
            Variable<String>(item.code),
            Variable<String>(contentTypeToStorage(item.type)),
            Variable<int>(item.revision),
          ],
          readsFrom: {
            _database.contentCatalogReads,
            _database.typedContentReads,
          },
        )
        .get();

    // Older locally created mock/legacy material can lack a typed body.
    if (rows.isEmpty) return null;
    if (rows.length != 1) {
      throw StateError('Non-unique exact typed content revision');
    }
    final row = rows.single;
    final checksum = row.read<String>('checksum');
    if (checksum != row.read<String>('typed_checksum') ||
        row.read<String>('body_kind') != item.type.name ||
        row.read<String>('title') != item.title ||
        row.read<String>('subtitle') != item.subtitle ||
        row.read<String>('description') != item.description ||
        row.read<String>('category') != item.category ||
        row.read<String>('level') != item.level ||
        row.read<int>('minutes') != item.minutes ||
        (row.read<int>('has_audio') != 0) != item.hasAudio) {
      throw StateError('Typed content identity/checksum mismatch');
    }

    // Reuse the production payload decoder. This fails closed on unknown body
    // fields, malformed lists, invalid segment timing and type mismatch.
    final decoded = const ContentPayloadDecoder().decode(<String, Object?>{
      'contentCode': item.code,
      'contentType': item.type.name,
      'revision': item.revision,
      'checksum': checksum,
      'title': row.read<String>('title'),
      'subtitle': row.read<String>('subtitle'),
      'description': row.read<String>('description'),
      'categoryCode': row.read<String>('category_code'),
      'categoryLabel': row.read<String>('category'),
      'levelCode': row.read<String>('level_code'),
      'levelLabel': row.read<String>('level'),
      'minutes': row.read<int>('minutes'),
      'hasAudio': row.read<int>('has_audio') != 0,
      'skillCodes': jsonDecode(row.read<String>('skill_codes_json')),
      'body': jsonDecode(row.read<String>('body_json')),
    });
    return switch (decoded) {
      Success<ContentPayload>(:final value) => value.body,
      FailureResult<ContentPayload>(:final failure) => throw StateError(
        'Persisted typed content failed validation: ${failure.code}',
      ),
    };
  }
}
