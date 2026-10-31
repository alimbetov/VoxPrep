import 'package:drift/drift.dart';

import '../../application/content_delivery/catalogue_payload.dart';
import '../../application/content_delivery/catalogue_revision_ref.dart';
import '../../application/content_delivery/content_manifest.dart';
import '../../application/content_delivery/learning_vertical.dart';
import '../../application/content_delivery/product_catalog.dart';
import '../../application/content_delivery/universal_catalogue_graph.dart';
import '../../application/content_delivery/universal_manifest_v2_policy.dart';
import '../../application/content_delivery/vertical_catalogue_presentation.dart';
import '../../application/result/result.dart';
import '../remote/universal_catalogue_decoder_registry.dart';
import 'database/careerspeak_database.dart';

/// Materializes one complete universal-catalogue graph under a staged
/// contentVersion. This class never mutates the learner-visible CURRENT pointer.
final class DriftUniversalCatalogueGraphMaterializer {
  const DriftUniversalCatalogueGraphMaterializer(
    this._database, {
    this.decoderRegistry = const UniversalCatalogueDecoderRegistry(),
  });

  final CareerSpeakDatabase _database;
  final UniversalCatalogueDecoderRegistry decoderRegistry;

  Future<Result<void>> materialize({
    required RootContentManifest root,
    required Iterable<CataloguePayload> payloads,
  }) async {
    final UniversalCatalogueGraph graph;
    try {
      if (root.schemaVersion < universalCatalogueManifestSchemaVersion) {
        throw const FormatException(
          'Universal graph materialization requires manifest schema v2.',
        );
      }
      requireUniversalCatalogueManifestV2(root);
      graph = _decodeGraph(root, payloads);
    } on Object catch (error) {
      return FailureResult<void>(
        ApplicationFailure(
          code: 'UNIVERSAL_CATALOGUE_GRAPH_INVALID',
          message: 'Universal catalogue graph is incomplete or inconsistent.',
          details: <String, Object?>{
            'errorType': error.runtimeType.toString(),
            'contentVersion': root.contentVersion,
          },
        ),
      );
    }

    try {
      await _database.transaction(() async {
        final currentRow = await _database
            .customSelect(
              '''
              SELECT current_content_version
              FROM content_manifest_states
              WHERE id = 1
              ''',
              readsFrom: <ResultSetImplementation>{
                _database.contentManifestStates,
              },
            )
            .getSingleOrNull();
        final currentContentVersion = currentRow?.read<int>(
          'current_content_version',
        );

        if (currentContentVersion == root.contentVersion) {
          final existing = await _database
              .customSelect(
                '''
                SELECT checksum
                FROM publication_snapshots
                WHERE content_version = ?
                ''',
                variables: <Variable<Object>>[
                  Variable<int>(root.contentVersion),
                ],
              )
              .getSingleOrNull();
          if (existing != null &&
              existing.read<String>('checksum') == root.checksum) {
            return;
          }
          throw StateError(
            'CURRENT contentVersion cannot be rebuilt by staged materializer',
          );
        }

        final existing = await _database
            .customSelect(
              '''
              SELECT schema_version, minimum_app_contract_version, checksum
              FROM publication_snapshots
              WHERE content_version = ?
              ''',
              variables: <Variable<Object>>[
                Variable<int>(root.contentVersion),
              ],
            )
            .getSingleOrNull();
        if (existing != null &&
            (existing.read<int>('schema_version') != root.schemaVersion ||
                existing.read<int>('minimum_app_contract_version') !=
                    root.minimumAppContractVersion ||
                existing.read<String>('checksum') != root.checksum)) {
          throw StateError(
            'immutable publication snapshot conflicts with staged root',
          );
        }

        if (existing != null) {
          await _database.customStatement(
            'DELETE FROM publication_snapshots WHERE content_version = ?',
            <Object?>[root.contentVersion],
          );
        }

        final now = DateTime.now().toUtc().millisecondsSinceEpoch;
        await _database.customStatement(
          '''
          INSERT INTO publication_snapshots (
            content_version,
            schema_version,
            minimum_app_contract_version,
            published_at,
            checksum,
            created_at
          ) VALUES (?, ?, ?, ?, ?, ?)
          ''',
          <Object?>[
            root.contentVersion,
            root.schemaVersion,
            root.minimumAppContractVersion,
            root.publishedAt.millisecondsSinceEpoch,
            root.checksum,
            now,
          ],
        );

        for (final section in graph.sections) {
          await _insertSection(root.contentVersion, section);
        }
        for (final vertical in graph.verticals) {
          await _insertVertical(root.contentVersion, vertical);
        }
        for (final goal in graph.goals) {
          await _insertGoal(root.contentVersion, goal);
        }
        for (final track in graph.tracks) {
          await _insertTrack(root.contentVersion, track);
        }
        for (final collection in graph.collections) {
          await _insertCollection(root.contentVersion, collection);
          for (final member in collection.members) {
            await _insertMember(root.contentVersion, collection.code, member);
          }
        }
        await _insertPresentation(root.contentVersion, graph.presentation);
      });

      return const Success(null);
    } on Object catch (error) {
      return FailureResult<void>(
        ApplicationFailure(
          code: 'UNIVERSAL_CATALOGUE_MATERIALIZATION_FAILED',
          message:
              'Universal catalogue graph could not be staged atomically.',
          retryable: true,
          details: <String, Object?>{
            'errorType': error.runtimeType.toString(),
            'contentVersion': root.contentVersion,
          },
        ),
      );
    }
  }

  UniversalCatalogueGraph _decodeGraph(
    RootContentManifest root,
    Iterable<CataloguePayload> payloads,
  ) {
    final payloadByKind = <CatalogueKind, CataloguePayload>{};
    for (final payload in payloads) {
      if (payloadByKind.putIfAbsent(payload.ref.kind, () => payload) != payload) {
        throw FormatException(
          'Duplicate payload for catalogue ${payload.ref.kind.wireName}.',
        );
      }
    }

    CataloguePayload exact(CatalogueKind kind) {
      final rootRefs = root.catalogues.where((ref) => ref.kind == kind).toList();
      if (rootRefs.length != 1) {
        throw FormatException(
          'Manifest must contain exactly one ${kind.wireName} revision.',
        );
      }
      final payload = payloadByKind[kind];
      if (payload == null) {
        throw FormatException('Missing payload for ${kind.wireName}.');
      }
      final expected = rootRefs.single;
      if (payload.ref.revision != expected.revision ||
          payload.ref.checksum != expected.checksum) {
        throw FormatException(
          'Payload ${kind.wireName} conflicts with exact manifest membership.',
        );
      }
      return payload;
    }

    final sections = decoderRegistry.decode(
      exact(CatalogueKind.verticalSections),
    ) as List<VerticalSectionProjection>;
    final verticals = decoderRegistry.decode(
      exact(CatalogueKind.verticals),
    ) as List<LearningVerticalProjection>;
    final presentation = decoderRegistry.decode(
      exact(CatalogueKind.verticalPresentation),
    ) as VerticalCataloguePresentation;
    final goals = decoderRegistry.decode(
      exact(CatalogueKind.learningGoals),
    ) as List<LearningGoalProjection>;
    final tracks = decoderRegistry.decode(
      exact(CatalogueKind.learningTracks),
    ) as List<LearningTrackProjection>;
    final collections = decoderRegistry.decode(
      exact(CatalogueKind.learningCollections),
    ) as List<LearningCollectionProjection>;

    return UniversalCatalogueGraph(
      sections: sections,
      verticals: verticals,
      goals: goals,
      tracks: tracks,
      collections: collections,
      presentation: presentation,
    );
  }

  Future<void> _insertSection(
    int contentVersion,
    VerticalSectionProjection section,
  ) {
    return _database.customStatement(
      '''
      INSERT INTO vertical_section_reads (
        content_version, code, title, description, icon_asset_id, sort_order, active
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        contentVersion,
        section.code,
        section.title,
        section.description,
        section.iconAssetId,
        section.sortOrder,
        section.active ? 1 : 0,
      ],
    );
  }

  Future<void> _insertVertical(
    int contentVersion,
    LearningVerticalProjection vertical,
  ) {
    return _database.customStatement(
      '''
      INSERT INTO learning_vertical_reads (
        content_version, code, section_code, title, description,
        icon_asset_id, sort_order, active
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        contentVersion,
        vertical.code,
        vertical.sectionCode,
        vertical.title,
        vertical.description,
        vertical.iconAssetId,
        vertical.sortOrder,
        vertical.active ? 1 : 0,
      ],
    );
  }

  Future<void> _insertGoal(int contentVersion, LearningGoalProjection goal) {
    return _database.customStatement(
      '''
      INSERT INTO learning_goal_reads (
        content_version, code, vertical_code, title, description, sort_order, active
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        contentVersion,
        goal.code,
        goal.verticalCode,
        goal.title,
        goal.description,
        goal.sortOrder,
        goal.active ? 1 : 0,
      ],
    );
  }

  Future<void> _insertTrack(int contentVersion, LearningTrackProjection track) {
    return _database.customStatement(
      '''
      INSERT INTO learning_track_reads (
        content_version, code, vertical_code, goal_code, title, description,
        level_code, career_track_code, sort_order, active
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        contentVersion,
        track.code,
        track.verticalCode,
        track.goalCode,
        track.title,
        track.description,
        track.levelCode,
        track.careerTrackCode,
        track.sortOrder,
        track.active ? 1 : 0,
      ],
    );
  }

  Future<void> _insertCollection(
    int contentVersion,
    LearningCollectionProjection collection,
  ) {
    return _database.customStatement(
      '''
      INSERT INTO learning_collection_reads (
        content_version, code, vertical_code, track_code, title, description,
        sort_order, active
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        contentVersion,
        collection.code,
        collection.verticalCode,
        collection.trackCode,
        collection.title,
        collection.description,
        collection.sortOrder,
        collection.active ? 1 : 0,
      ],
    );
  }

  Future<void> _insertMember(
    int contentVersion,
    String collectionCode,
    LearningCollectionMember member,
  ) {
    final content = member.contentRef;
    final practiceTest = member.practiceTestRef;
    return _database.customStatement(
      '''
      INSERT INTO learning_collection_member_reads (
        content_version, collection_code, position, member_type,
        content_code, content_type, content_revision, content_checksum,
        practice_test_code, practice_test_revision, practice_test_checksum
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        contentVersion,
        collectionCode,
        member.position,
        member.type.wireName,
        content?.contentCode,
        content?.contentType.name,
        content?.revision,
        content?.checksum,
        practiceTest?.practiceTestCode,
        practiceTest?.revision,
        practiceTest?.checksum,
      ],
    );
  }

  Future<void> _insertPresentation(
    int contentVersion,
    VerticalCataloguePresentation presentation,
  ) {
    return _database.customStatement(
      '''
      INSERT INTO vertical_presentation_reads (
        content_version, mode, show_featured, show_see_all, featured_section_code
      ) VALUES (?, ?, ?, ?, ?)
      ''',
      <Object?>[
        contentVersion,
        presentation.mode.wireName,
        presentation.showFeatured ? 1 : 0,
        presentation.showSeeAll ? 1 : 0,
        presentation.featuredSectionCode,
      ],
    );
  }
}
