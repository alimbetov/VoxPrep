import 'package:careerspeak_app/application/assessment/assessment_revision_loader.dart';
import 'package:careerspeak_app/application/content_delivery/catalogue_payload.dart';
import 'package:careerspeak_app/application/content_delivery/catalogue_revision_ref.dart';
import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_coordinator.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/ports/universal_catalogue_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_assessment_revision_repository.dart';
import 'package:careerspeak_app/data/local/drift_publication_snapshot_stager.dart';
import 'package:careerspeak_app/data/local/drift_sync_journal.dart';
import 'package:careerspeak_app/data/local/drift_sync_plan_executor.dart';
import 'package:careerspeak_app/data/local/drift_universal_catalogue_graph_materializer.dart';
import 'package:careerspeak_app/data/local/drift_universal_catalogue_repository.dart';
import 'package:careerspeak_app/data/mock/demo_assessment_payload_gateway.dart';
import 'package:careerspeak_app/data/mock/demo_catalogue_payload_gateway.dart';
import 'package:careerspeak_app/data/mock/demo_content_manifest_gateway.dart';
import 'package:careerspeak_app/data/mock/demo_content_payload_gateway.dart';
import 'package:careerspeak_app/data/mock/demo_vertical_catalogue_fixture.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('V12 universal catalogue adversarial qualification', () {
    late CareerSpeakDatabase database;
    late Map<String, CataloguePayload> demoPayloads;
    late RootContentManifest currentRoot;

    setUp(() async {
      database = CareerSpeakDatabase(NativeDatabase.memory());
      demoPayloads = buildDemoVerticalCataloguePayloads();
      final manifestGateway = DemoContentManifestGateway(
        cataloguePayloads: demoPayloads.values,
        latency: Duration.zero,
      );
      final assessmentRepository = DriftAssessmentRevisionRepository(database);
      final coordinator = ContentSyncCoordinator(
        journal: DriftSyncJournal(database),
        manifestGateway: manifestGateway,
        planner: const ContentSyncPlanner(),
        executor: DriftSyncPlanExecutor(
          database,
          manifestGateway,
          DemoContentPayloadGateway(latency: Duration.zero),
        ),
        snapshotStager: DriftPublicationSnapshotStager(
          database,
          AssessmentRevisionLoader(
            gateway: DemoAssessmentPayloadGateway(latency: Duration.zero),
            repository: assessmentRepository,
          ),
          DemoCataloguePayloadGateway(
            payloads: demoPayloads,
            latency: Duration.zero,
          ),
        ),
      );

      final synced = await coordinator.synchronize(
        runId: 'v12-baseline',
        trigger: SyncTrigger.manual,
        translationLocale: 'en',
      );
      expect(synced, isA<Success<ContentSyncOutcome>>());
      final rootFetch = (await manifestGateway.fetchRootManifest())
          .getOrThrow();
      currentRoot = (rootFetch as RootManifestChanged).manifest;
      await _expectCurrent(database, version: 1, verticalCount: 8);
    });

    tearDown(() => database.close());

    test(
      'duplicate business codes are rejected and CURRENT survives',
      () async {
        final payloads = _replaceItems(
          demoPayloads,
          CatalogueKind.learningGoals,
          (items) => <Object>[...items, _copyMap(items.first)],
        );

        await _expectMaterializationFailure(
          database,
          _rootVersion(currentRoot, 2, checksumChar: '1'),
          payloads.values,
        );
        await _expectCurrent(database, version: 1, verticalCount: 8);
      },
    );

    test('dangling ownership is rejected and CURRENT survives', () async {
      final payloads = _replaceItems(
        demoPayloads,
        CatalogueKind.learningGoals,
        (items) {
          final result = [...items];
          final first = _copyMap(result.first);
          first['verticalCode'] = 'MISSING_VERTICAL';
          result[0] = first;
          return result;
        },
      );

      await _expectMaterializationFailure(
        database,
        _rootVersion(currentRoot, 3, checksumChar: '2'),
        payloads.values,
      );
      await _expectCurrent(database, version: 1, verticalCount: 8);
    });

    test(
      'cross-vertical track ownership is rejected and CURRENT survives',
      () async {
        final payloads = _replaceItems(
          demoPayloads,
          CatalogueKind.learningTracks,
          (items) {
            final result = [...items];
            final first = _copyMap(result.first);
            first['verticalCode'] = 'MEDICAL_ENGLISH';
            result[0] = first;
            return result;
          },
        );

        await _expectMaterializationFailure(
          database,
          _rootVersion(currentRoot, 4, checksumChar: '3'),
          payloads.values,
        );
        await _expectCurrent(database, version: 1, verticalCount: 8);
      },
    );

    test(
      'broken collection member order is rejected and CURRENT survives',
      () async {
        final payloads = _replaceItems(
          demoPayloads,
          CatalogueKind.learningCollections,
          (items) {
            final result = [...items];
            final first = _copyMap(result.first);
            final members = (first['members']! as List).cast<Object>().toList();
            final member = _copyMap(members.first);
            member['position'] = 1;
            members[0] = member;
            first['members'] = members;
            result[0] = first;
            return result;
          },
        );

        await _expectMaterializationFailure(
          database,
          _rootVersion(currentRoot, 5, checksumChar: '4'),
          payloads.values,
        );
        await _expectCurrent(database, version: 1, verticalCount: 8);
      },
    );

    test(
      'wrong exact catalogue checksum is rejected and CURRENT survives',
      () async {
        final payloads = Map<String, CataloguePayload>.from(demoPayloads);
        final original = _payloadOfKind(
          payloads.values,
          CatalogueKind.verticals,
        );
        final wrongRef = CatalogueRevisionRef(
          kind: original.ref.kind,
          revision: original.ref.revision,
          checksum:
              'abababababababababababababababababababababababababababababababab',
        );
        final wrong = CataloguePayload(
          ref: wrongRef,
          items: original.items,
          wireJson: <String, Object?>{
            ...original.wireJson,
            'checksum': wrongRef.checksum,
          },
        );
        payloads.remove(DemoCataloguePayloadGateway.keyOf(original.ref));
        payloads[DemoCataloguePayloadGateway.keyOf(wrongRef)] = wrong;

        await _expectMaterializationFailure(
          database,
          _rootVersion(currentRoot, 6, checksumChar: '5'),
          payloads.values,
        );
        await _expectCurrent(database, version: 1, verticalCount: 8);
      },
    );

    test(
      'partial six-core manifest is rejected and CURRENT survives',
      () async {
        final partial = _rootVersion(
          currentRoot,
          7,
          checksumChar: '6',
          catalogues: currentRoot.catalogues.where(
            (ref) => ref.kind != CatalogueKind.learningCollections,
          ),
        );

        await _expectMaterializationFailure(
          database,
          partial,
          demoPayloads.values,
        );
        await _expectCurrent(database, version: 1, verticalCount: 8);
      },
    );

    test('corrupted staged Drift rows never leak through CURRENT', () async {
      final staged = _rootVersion(currentRoot, 8, checksumChar: '7');
      final materialized = await DriftUniversalCatalogueGraphMaterializer(
        database,
      ).materialize(root: staged, payloads: demoPayloads.values);
      expect(materialized, isA<Success<void>>());

      await database.customStatement('PRAGMA foreign_keys = OFF');
      try {
        await database.customStatement('''
          UPDATE learning_track_reads
          SET goal_code = 'CORRUPTED_GOAL'
          WHERE content_version = 8
          ''');
      } finally {
        await database.customStatement('PRAGMA foreign_keys = ON');
      }

      await _expectCurrent(database, version: 1, verticalCount: 8);
    });

    test(
      'stale valid staged snapshot remains invisible until CURRENT switch',
      () async {
        final staged = _rootVersion(currentRoot, 9, checksumChar: '8');
        final materialized = await DriftUniversalCatalogueGraphMaterializer(
          database,
        ).materialize(root: staged, payloads: demoPayloads.values);
        expect(materialized, isA<Success<void>>());

        final stagedRow = await database
            .customSelect(
              'SELECT content_version FROM publication_snapshots WHERE content_version = 9',
            )
            .getSingleOrNull();
        expect(stagedRow, isNotNull);
        await _expectCurrent(database, version: 1, verticalCount: 8);
      },
    );

    test('failed publication staging cannot replace old CURRENT', () async {
      final corrupted = _replaceItems(
        demoPayloads,
        CatalogueKind.learningTracks,
        (items) {
          final result = [...items];
          final first = _copyMap(result.first);
          first['goalCode'] = 'NO_SUCH_GOAL';
          result[0] = first;
          return result;
        },
      );
      final target = _rootVersion(currentRoot, 10, checksumChar: '9');
      final stager = DriftPublicationSnapshotStager(
        database,
        AssessmentRevisionLoader(
          gateway: DemoAssessmentPayloadGateway(latency: Duration.zero),
          repository: DriftAssessmentRevisionRepository(database),
        ),
        DemoCataloguePayloadGateway(
          payloads: corrupted,
          latency: Duration.zero,
        ),
      );

      final staged = await stager.stage(target);
      expect(staged, isA<FailureResult<void>>());
      await _expectCurrent(database, version: 1, verticalCount: 8);
    });
  });
}

Future<void> _expectMaterializationFailure(
  CareerSpeakDatabase database,
  RootContentManifest root,
  Iterable<CataloguePayload> payloads,
) async {
  final result = await DriftUniversalCatalogueGraphMaterializer(
    database,
  ).materialize(root: root, payloads: payloads);
  expect(result, isA<FailureResult<void>>());
}

Future<void> _expectCurrent(
  CareerSpeakDatabase database, {
  required int version,
  required int verticalCount,
}) async {
  final result = await DriftUniversalCatalogueRepository(
    database,
  ).readCurrent();
  expect(result, isA<Success<CurrentUniversalCatalogueSnapshot?>>());
  final snapshot =
      (result as Success<CurrentUniversalCatalogueSnapshot?>).value;
  expect(snapshot, isNotNull);
  expect(snapshot!.contentVersion, version);
  expect(snapshot.graph.verticals, hasLength(verticalCount));
}

RootContentManifest _rootVersion(
  RootContentManifest source,
  int contentVersion, {
  required String checksumChar,
  Iterable<CatalogueRevisionRef>? catalogues,
}) {
  return RootContentManifest(
    schemaVersion: source.schemaVersion,
    contentVersion: contentVersion,
    minimumAppContractVersion: source.minimumAppContractVersion,
    publishedAt: source.publishedAt.add(Duration(minutes: contentVersion)),
    checksum: List<String>.filled(64, checksumChar).join(),
    packs: source.packs,
    practiceTests: source.practiceTests,
    catalogues: catalogues ?? source.catalogues,
    localeFallbacks: source.localeFallbacks,
    tombstones: source.tombstones,
  );
}

Map<String, CataloguePayload> _replaceItems(
  Map<String, CataloguePayload> source,
  CatalogueKind kind,
  List<Object> Function(List<Object> items) mutate,
) {
  final result = Map<String, CataloguePayload>.from(source);
  final original = _payloadOfKind(result.values, kind);
  final items = mutate(original.items);
  final replacement = CataloguePayload(
    ref: original.ref,
    items: items,
    wireJson: <String, Object?>{...original.wireJson, 'items': items},
  );
  result[DemoCataloguePayloadGateway.keyOf(original.ref)] = replacement;
  return result;
}

CataloguePayload _payloadOfKind(
  Iterable<CataloguePayload> payloads,
  CatalogueKind kind,
) {
  return payloads.singleWhere((payload) => payload.ref.kind == kind);
}

Map<String, dynamic> _copyMap(Object value) {
  return Map<String, dynamic>.from(value as Map<String, dynamic>);
}
