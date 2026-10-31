import 'package:careerspeak_app/application/content_delivery/catalogue_payload.dart';
import 'package:careerspeak_app/application/content_delivery/catalogue_revision_ref.dart';
import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_universal_catalogue_graph_materializer.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  group('DriftUniversalCatalogueGraphMaterializer', () {
    test('materializes six-core graph without changing CURRENT', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final now = DateTime.utc(2026, 10, 31, 19);

      await database.into(database.contentManifestStates).insert(
        ContentManifestStatesCompanion.insert(
          id: const Value(1),
          schemaVersion: 2,
          currentContentVersion: 100,
          currentManifestChecksum: _hash,
          updatedAt: now,
        ),
      );

      final root = _root(101);
      final result = await DriftUniversalCatalogueGraphMaterializer(
        database,
      ).materialize(root: root, payloads: _payloads());

      expect(result, isA<Success<void>>());

      final current = await database
          .customSelect(
            'SELECT current_content_version FROM content_manifest_states WHERE id = 1',
          )
          .getSingle();
      expect(current.read<int>('current_content_version'), 100);

      final snapshot = await database
          .customSelect(
            'SELECT checksum FROM publication_snapshots WHERE content_version = 101',
          )
          .getSingle();
      expect(snapshot.read<String>('checksum'), _hash);

      expect(
        await database
            .customSelect(
              'SELECT code FROM vertical_section_reads WHERE content_version = 101',
            )
            .get(),
        hasLength(1),
      );
      expect(
        await database
            .customSelect(
              'SELECT code FROM learning_vertical_reads WHERE content_version = 101',
            )
            .get(),
        hasLength(1),
      );
      expect(
        await database
            .customSelect(
              'SELECT code FROM learning_goal_reads WHERE content_version = 101',
            )
            .get(),
        hasLength(1),
      );
      expect(
        await database
            .customSelect(
              'SELECT code FROM learning_track_reads WHERE content_version = 101',
            )
            .get(),
        hasLength(1),
      );
      expect(
        await database
            .customSelect(
              'SELECT code FROM learning_collection_reads WHERE content_version = 101',
            )
            .get(),
        hasLength(1),
      );

      final members = await database.customSelect(
        '''
        SELECT position, member_type
        FROM learning_collection_member_reads
        WHERE content_version = 101 AND collection_code = 'COLLECTION_ALPHA'
        ORDER BY position
        ''',
      ).get();
      expect(
        members
            .map(
              (row) => '${row.read<int>('position')}:${row.read<String>('member_type')}',
            )
            .toList(),
        <String>['0:CONTENT', '1:PRACTICE_TEST'],
      );
    });

    test('rejects cross-vertical graph before writing snapshot rows', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      await database.customSelect('SELECT 1').getSingle();

      final payloads = _payloads().toList();
      final trackIndex = payloads.indexWhere(
        (payload) => payload.ref.kind == CatalogueKind.learningTracks,
      );
      payloads[trackIndex] = _payload(
        CatalogueKind.learningTracks,
        <Object>[
          <String, dynamic>{
            'code': 'TRACK_ALPHA',
            'verticalCode': 'OTHER_VERTICAL',
            'goalCode': 'GOAL_ALPHA',
            'title': 'Track',
            'description': 'Track description',
            'levelCode': 'B2',
            'careerTrackCode': null,
            'sortOrder': 0,
            'active': true,
          },
        ],
      );

      final result = await DriftUniversalCatalogueGraphMaterializer(
        database,
      ).materialize(root: _root(102), payloads: payloads);

      expect(result, isA<FailureResult<void>>());
      expect(
        (result as FailureResult<void>).failure.code,
        'UNIVERSAL_CATALOGUE_GRAPH_INVALID',
      );
      expect(
        await database
            .customSelect(
              'SELECT * FROM publication_snapshots WHERE content_version = 102',
            )
            .get(),
        isEmpty,
      );
    });

    test('rejects payload revision that differs from exact root membership', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      await database.customSelect('SELECT 1').getSingle();

      final payloads = _payloads().toList();
      final verticalIndex = payloads.indexWhere(
        (payload) => payload.ref.kind == CatalogueKind.verticals,
      );
      final original = payloads[verticalIndex];
      payloads[verticalIndex] = CataloguePayload(
        ref: CatalogueRevisionRef(
          kind: CatalogueKind.verticals,
          revision: 99,
          checksum: _hash,
        ),
        items: original.items,
        wireJson: <String, Object?>{
          'kind': CatalogueKind.verticals.wireName,
          'revision': 99,
          'checksum': _hash,
          'items': original.items,
        },
      );

      final result = await DriftUniversalCatalogueGraphMaterializer(
        database,
      ).materialize(root: _root(103), payloads: payloads);

      expect(result, isA<FailureResult<void>>());
      expect(
        (result as FailureResult<void>).failure.code,
        'UNIVERSAL_CATALOGUE_GRAPH_INVALID',
      );
    });

    test('rejects practice test outside exact snapshot membership', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      await database.customSelect('SELECT 1').getSingle();

      final root = RootContentManifest(
        schemaVersion: 2,
        contentVersion: 104,
        minimumAppContractVersion: 2,
        publishedAt: DateTime.utc(2026, 10, 31, 19),
        checksum: _hash,
        packs: const <PackRevisionRef>[],
        practiceTests: <PracticeTestRevisionRef>[
          PracticeTestRevisionRef(
            practiceTestCode: 'TEST_ALPHA',
            revision: 2,
            checksum: _hash,
          ),
        ],
        catalogues: _catalogueRefs(),
        tombstones: const <ContentTombstone>[],
      );

      final result = await DriftUniversalCatalogueGraphMaterializer(
        database,
      ).materialize(root: root, payloads: _payloads());

      expect(result, isA<FailureResult<void>>());
      expect(
        (result as FailureResult<void>).failure.code,
        'UNIVERSAL_CATALOGUE_GRAPH_INVALID',
      );
    });
  });
}

RootContentManifest _root(int contentVersion) {
  return RootContentManifest(
    schemaVersion: 2,
    contentVersion: contentVersion,
    minimumAppContractVersion: 2,
    publishedAt: DateTime.utc(2026, 10, 31, 19),
    checksum: _hash,
    packs: const <PackRevisionRef>[],
    practiceTests: <PracticeTestRevisionRef>[
      PracticeTestRevisionRef(
        practiceTestCode: 'TEST_ALPHA',
        revision: 1,
        checksum: _hash,
      ),
    ],
    catalogues: _catalogueRefs(),
    tombstones: const <ContentTombstone>[],
  );
}

List<CatalogueRevisionRef> _catalogueRefs() {
  return <CatalogueRevisionRef>[
    for (final kind in <CatalogueKind>[
      CatalogueKind.verticalSections,
      CatalogueKind.verticals,
      CatalogueKind.verticalPresentation,
      CatalogueKind.learningGoals,
      CatalogueKind.learningTracks,
      CatalogueKind.learningCollections,
    ])
      CatalogueRevisionRef(kind: kind, revision: 1, checksum: _hash),
  ];
}

Iterable<CataloguePayload> _payloads() sync* {
  yield _payload(
    CatalogueKind.verticalSections,
    <Object>[
      <String, dynamic>{
        'code': 'SECTION_ALPHA',
        'title': 'Section',
        'description': null,
        'iconAssetId': null,
        'sortOrder': 0,
        'active': true,
      },
    ],
  );
  yield _payload(
    CatalogueKind.verticals,
    <Object>[
      <String, dynamic>{
        'code': 'VERTICAL_ALPHA',
        'sectionCode': 'SECTION_ALPHA',
        'title': 'Vertical',
        'description': 'Vertical description',
        'iconAssetId': 'asset-vertical',
        'sortOrder': 0,
        'active': true,
      },
    ],
  );
  yield _payload(
    CatalogueKind.verticalPresentation,
    <Object>[
      <String, dynamic>{
        'mode': 'SHELVES',
        'showFeatured': false,
        'showSeeAll': true,
        'featuredSectionCode': null,
      },
    ],
  );
  yield _payload(
    CatalogueKind.learningGoals,
    <Object>[
      <String, dynamic>{
        'code': 'GOAL_ALPHA',
        'verticalCode': 'VERTICAL_ALPHA',
        'title': 'Goal',
        'description': 'Goal description',
        'sortOrder': 0,
        'active': true,
      },
    ],
  );
  yield _payload(
    CatalogueKind.learningTracks,
    <Object>[
      <String, dynamic>{
        'code': 'TRACK_ALPHA',
        'verticalCode': 'VERTICAL_ALPHA',
        'goalCode': 'GOAL_ALPHA',
        'title': 'Track',
        'description': 'Track description',
        'levelCode': 'B2',
        'careerTrackCode': null,
        'sortOrder': 0,
        'active': true,
      },
    ],
  );
  yield _payload(
    CatalogueKind.learningCollections,
    <Object>[
      <String, dynamic>{
        'code': 'COLLECTION_ALPHA',
        'verticalCode': 'VERTICAL_ALPHA',
        'trackCode': 'TRACK_ALPHA',
        'title': 'Collection',
        'description': 'Collection description',
        'sortOrder': 0,
        'active': true,
        'members': <Object>[
          <String, dynamic>{
            'position': 0,
            'type': 'CONTENT',
            'content': <String, dynamic>{
              'contentCode': 'CONTENT_ALPHA',
              'contentType': 'topic',
              'revision': 1,
              'checksum': _hash,
            },
            'practiceTest': null,
          },
          <String, dynamic>{
            'position': 1,
            'type': 'PRACTICE_TEST',
            'content': null,
            'practiceTest': <String, dynamic>{
              'practiceTestCode': 'TEST_ALPHA',
              'revision': 1,
              'checksum': _hash,
            },
          },
        ],
      },
    ],
  );
}

CataloguePayload _payload(CatalogueKind kind, List<Object> items) {
  final ref = CatalogueRevisionRef(kind: kind, revision: 1, checksum: _hash);
  return CataloguePayload(
    ref: ref,
    items: items,
    wireJson: <String, Object?>{
      'kind': kind.wireName,
      'revision': 1,
      'checksum': _hash,
      'items': items,
    },
  );
}
