import 'dart:convert';

import 'package:drift/drift.dart';

import '../../application/assessment/assessment_revision_loader.dart';
import '../../application/content_delivery/catalogue_payload.dart';
import '../../application/content_delivery/content_manifest.dart';
import '../../application/ports/catalogue_payload_gateway.dart';
import '../../application/ports/content_manifest_gateway.dart';
import '../../application/ports/publication_snapshot_stager.dart';
import '../../application/result/result.dart';
import 'database/careerspeak_database.dart';
import 'drift_universal_catalogue_graph_materializer.dart';
import 'publication_snapshot_storage.dart';

final class DriftPublicationSnapshotStager
    implements PublicationSnapshotStager {
  DriftPublicationSnapshotStager(
    this._database,
    this._assessmentLoader,
    this._catalogueGateway, {
    ContentManifestGateway? manifestGateway,
    DateTime Function()? now,
  }) : _manifestGateway = manifestGateway,
       _now = now ?? (() => DateTime.now().toUtc());

  final CareerSpeakDatabase _database;
  final AssessmentRevisionLoader _assessmentLoader;
  final CataloguePayloadGateway _catalogueGateway;
  final ContentManifestGateway? _manifestGateway;
  final DateTime Function() _now;

  @override
  Future<Result<void>> stage(RootContentManifest target) async {
    try {
      await PublicationSnapshotStorage(_database).ensureReady();
    } catch (error) {
      return FailureResult<void>(
        ApplicationFailure(
          code: 'PUBLICATION_SNAPSHOT_STORAGE_FAILED',
          message: 'Publication snapshot storage could not be initialized.',
          retryable: true,
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }

    for (final ref in target.practiceTests) {
      final loaded = await _assessmentLoader.load(
        practiceTestCode: ref.practiceTestCode,
        revision: ref.revision,
        checksum: ref.checksum,
      );
      if (loaded case FailureResult(:final failure)) {
        return FailureResult<void>(failure);
      }
    }

    final cataloguePayloads = <CataloguePayload>[];
    for (final ref in target.catalogues) {
      final fetched = await _catalogueGateway.fetch(ref);
      if (fetched case FailureResult<CataloguePayload>(:final failure)) {
        return FailureResult<void>(failure);
      }
      cataloguePayloads.add((fetched as Success<CataloguePayload>).value);
    }

    final exactPackManifestsResult = await _fetchExactPackManifests(target);
    if (exactPackManifestsResult
        case FailureResult<List<PackContentManifest>>(:final failure)) {
      return FailureResult<void>(failure);
    }
    final exactPackManifests =
        (exactPackManifestsResult as Success<List<PackContentManifest>>).value;

    try {
      await _database.transaction(() async {
        final now = _now();
        for (final payload in cataloguePayloads) {
          final existing = await _database
              .customSelect(
                '''
            SELECT checksum, payload_json
            FROM catalogue_revision_reads
            WHERE catalogue_kind = ? AND revision = ?
            ''',
                variables: <Variable<Object>>[
                  Variable<String>(payload.ref.kind.wireName),
                  Variable<int>(payload.ref.revision),
                ],
              )
              .getSingleOrNull();
          final payloadJson = jsonEncode(payload.wireJson);
          if (existing != null &&
              (existing.read<String>('checksum') != payload.ref.checksum ||
                  existing.read<String>('payload_json') != payloadJson)) {
            throw StateError(
              'immutable catalogue revision conflicts with local cache',
            );
          }
          if (existing == null) {
            await _database.customStatement(
              '''
              INSERT INTO catalogue_revision_reads (
                catalogue_kind,
                revision,
                checksum,
                payload_json,
                created_at
              ) VALUES (?, ?, ?, ?, ?)
              ''',
              <Object?>[
                payload.ref.kind.wireName,
                payload.ref.revision,
                payload.ref.checksum,
                payloadJson,
                now.millisecondsSinceEpoch,
              ],
            );
          }
        }

        await _database.customStatement(
          'DELETE FROM publication_practice_test_refs WHERE content_version = ?',
          <Object?>[target.contentVersion],
        );
        await _database.customStatement(
          'DELETE FROM publication_catalogue_refs WHERE content_version = ?',
          <Object?>[target.contentVersion],
        );

        for (final ref in target.practiceTests) {
          await _database.customStatement(
            '''
            INSERT INTO publication_practice_test_refs (
              content_version,
              practice_test_code,
              revision,
              checksum
            ) VALUES (?, ?, ?, ?)
            ''',
            <Object?>[
              target.contentVersion,
              ref.practiceTestCode,
              ref.revision,
              ref.checksum,
            ],
          );
        }

        for (final ref in target.catalogues) {
          await _database.customStatement(
            '''
            INSERT INTO publication_catalogue_refs (
              content_version,
              catalogue_kind,
              revision,
              checksum
            ) VALUES (?, ?, ?, ?)
            ''',
            <Object?>[
              target.contentVersion,
              ref.kind.wireName,
              ref.revision,
              ref.checksum,
            ],
          );
        }

        // Raw auxiliary tables are intentionally outside the generated Drift
        // schema, so they do not invalidate active Drift watchers themselves.
        // If this is an idempotent repair of the already-CURRENT snapshot, touch
        // only runtime metadata to make UI streams re-evaluate exact membership.
        // This timestamp is not part of PublicationSnapshot identity/checksum.
        final current = await (_database.select(
          _database.contentManifestStates,
        )..where((row) => row.id.equals(1))).getSingleOrNull();
        if (current != null &&
            current.currentContentVersion == target.contentVersion) {
          await (_database.update(_database.contentManifestStates)
                ..where((row) => row.id.equals(1)))
              .write(ContentManifestStatesCompanion(updatedAt: Value(now)));
        }
      });
    } catch (error) {
      return FailureResult<void>(
        ApplicationFailure(
          code: 'PUBLICATION_SNAPSHOT_STAGING_FAILED',
          message: 'Exact publication membership could not be staged locally.',
          retryable: true,
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }

    // Schema v1 remains supported by the legacy publication path. Schema v2+
    // additionally requires a fully decoded and graph-closed local projection.
    if (target.schemaVersion >= 2) {
      final materialized = await DriftUniversalCatalogueGraphMaterializer(
        _database,
      ).materialize(
        root: target,
        payloads: cataloguePayloads,
        packManifests: exactPackManifests,
      );
      if (materialized case FailureResult<void>(:final failure)) {
        return FailureResult<void>(failure);
      }
    }

    return const Success(null);
  }

  Future<Result<List<PackContentManifest>>> _fetchExactPackManifests(
    RootContentManifest target,
  ) async {
    if (target.packs.isEmpty) {
      return const Success<List<PackContentManifest>>(<PackContentManifest>[]);
    }

    final gateway = _manifestGateway;
    if (gateway == null) {
      // Backward-compatible path for legacy callers that only stage schema v1.
      // Schema v2+ icon validation will fail closed unless pack metadata is
      // already available in the local database.
      return const Success<List<PackContentManifest>>(<PackContentManifest>[]);
    }

    final manifests = <PackContentManifest>[];
    for (final ref in target.packs) {
      final fetched = await gateway.fetchPackManifest(
        identity: ref.identity,
        revision: ref.revision,
        checksum: ref.checksum,
      );
      switch (fetched) {
        case FailureResult<PackContentManifest>(:final failure):
          return FailureResult<List<PackContentManifest>>(failure);
        case Success<PackContentManifest>(:final value):
          if (value.identity != ref.identity ||
              value.revision != ref.revision ||
              value.checksum != ref.checksum) {
            return const FailureResult<List<PackContentManifest>>(
              ApplicationFailure(
                code: 'PUBLICATION_SNAPSHOT_IDENTITY_CONFLICT',
                message:
                    'Fetched pack manifest does not match exact publication membership.',
              ),
            );
          }
          manifests.add(value);
      }
    }

    return Success<List<PackContentManifest>>(
      List<PackContentManifest>.unmodifiable(manifests),
    );
  }
}
