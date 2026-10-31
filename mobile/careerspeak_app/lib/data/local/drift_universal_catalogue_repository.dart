import 'package:drift/drift.dart';

import '../../application/content_delivery/learning_vertical.dart';
import '../../application/content_delivery/product_catalog.dart';
import '../../application/content_delivery/universal_catalogue_graph.dart';
import '../../application/content_delivery/vertical_catalogue_presentation.dart';
import '../../application/ports/universal_catalogue_repository.dart';
import '../../application/result/result.dart';
import '../../domain/content_item.dart';
import 'database/careerspeak_database.dart';

final class DriftUniversalCatalogueRepository
    implements UniversalCatalogueRepository {
  const DriftUniversalCatalogueRepository(this._database);

  final CareerSpeakDatabase _database;

  @override
  Future<Result<CurrentUniversalCatalogueSnapshot?>> readCurrent() async {
    try {
      final state = await _database.customSelect('''
        SELECT current_content_version
        FROM content_manifest_states
        WHERE id = 1
      ''').getSingleOrNull();

      if (state == null) {
        return const Success<CurrentUniversalCatalogueSnapshot?>(null);
      }

      final contentVersion = state.read<int>('current_content_version');
      if (contentVersion <= 0) {
        return const Success<CurrentUniversalCatalogueSnapshot?>(null);
      }

      final snapshot = await _database
          .customSelect(
            '''
        SELECT content_version
        FROM publication_snapshots
        WHERE content_version = ?
        ''',
            variables: [Variable<int>(contentVersion)],
          )
          .getSingleOrNull();
      if (snapshot == null) {
        return const FailureResult<CurrentUniversalCatalogueSnapshot?>(
          ApplicationFailure(
            code: 'UNIVERSAL_CATALOGUE_CURRENT_MISSING',
            message:
                'CURRENT publication snapshot is not materialized locally.',
          ),
        );
      }

      final graph = UniversalCatalogueGraph(
        sections: await _readSections(contentVersion),
        verticals: await _readVerticals(contentVersion),
        goals: await _readGoals(contentVersion),
        tracks: await _readTracks(contentVersion),
        collections: await _readCollections(contentVersion),
        presentation: await _readPresentation(contentVersion),
      );

      return Success<CurrentUniversalCatalogueSnapshot?>(
        CurrentUniversalCatalogueSnapshot(
          contentVersion: contentVersion,
          graph: graph,
        ),
      );
    } on Object catch (error) {
      return FailureResult<CurrentUniversalCatalogueSnapshot?>(
        ApplicationFailure(
          code: 'UNIVERSAL_CATALOGUE_CURRENT_INVALID',
          message:
              'CURRENT universal catalogue graph could not be reconstructed.',
          retryable: false,
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }
  }

  Future<List<VerticalSectionProjection>> _readSections(int version) async {
    final rows = await _database
        .customSelect(
          '''
      SELECT code, title, description, icon_asset_id, sort_order, active
      FROM vertical_section_reads
      WHERE content_version = ?
      ORDER BY sort_order, code
      ''',
          variables: [Variable<int>(version)],
        )
        .get();
    return [
      for (final row in rows)
        VerticalSectionProjection(
          code: row.read<String>('code'),
          title: row.read<String>('title'),
          description: row.readNullable<String>('description'),
          iconAssetId: row.readNullable<String>('icon_asset_id'),
          sortOrder: row.read<int>('sort_order'),
          active: row.read<int>('active') == 1,
        ),
    ];
  }

  Future<List<LearningVerticalProjection>> _readVerticals(int version) async {
    final rows = await _database
        .customSelect(
          '''
      SELECT code, section_code, title, description, icon_asset_id, sort_order, active
      FROM learning_vertical_reads
      WHERE content_version = ?
      ORDER BY sort_order, code
      ''',
          variables: [Variable<int>(version)],
        )
        .get();
    return [
      for (final row in rows)
        LearningVerticalProjection(
          code: row.read<String>('code'),
          sectionCode: row.read<String>('section_code'),
          title: row.read<String>('title'),
          description: row.read<String>('description'),
          iconAssetId: row.read<String>('icon_asset_id'),
          sortOrder: row.read<int>('sort_order'),
          active: row.read<int>('active') == 1,
        ),
    ];
  }

  Future<List<LearningGoalProjection>> _readGoals(int version) async {
    final rows = await _database
        .customSelect(
          '''
      SELECT code, vertical_code, title, description, sort_order, active
      FROM learning_goal_reads
      WHERE content_version = ?
      ORDER BY sort_order, code
      ''',
          variables: [Variable<int>(version)],
        )
        .get();
    return [
      for (final row in rows)
        LearningGoalProjection(
          code: row.read<String>('code'),
          verticalCode: row.read<String>('vertical_code'),
          title: row.read<String>('title'),
          description: row.read<String>('description'),
          sortOrder: row.read<int>('sort_order'),
          active: row.read<int>('active') == 1,
        ),
    ];
  }

  Future<List<LearningTrackProjection>> _readTracks(int version) async {
    final rows = await _database
        .customSelect(
          '''
      SELECT code, vertical_code, goal_code, title, description,
             level_code, career_track_code, sort_order, active
      FROM learning_track_reads
      WHERE content_version = ?
      ORDER BY sort_order, code
      ''',
          variables: [Variable<int>(version)],
        )
        .get();
    return [
      for (final row in rows)
        LearningTrackProjection(
          code: row.read<String>('code'),
          verticalCode: row.read<String>('vertical_code'),
          goalCode: row.read<String>('goal_code'),
          title: row.read<String>('title'),
          description: row.read<String>('description'),
          levelCode: row.read<String>('level_code'),
          careerTrackCode: row.readNullable<String>('career_track_code'),
          sortOrder: row.read<int>('sort_order'),
          active: row.read<int>('active') == 1,
        ),
    ];
  }

  Future<List<LearningCollectionProjection>> _readCollections(
    int version,
  ) async {
    final rows = await _database
        .customSelect(
          '''
      SELECT code, vertical_code, track_code, title, description, sort_order, active
      FROM learning_collection_reads
      WHERE content_version = ?
      ORDER BY sort_order, code
      ''',
          variables: [Variable<int>(version)],
        )
        .get();

    final result = <LearningCollectionProjection>[];
    for (final row in rows) {
      final code = row.read<String>('code');
      result.add(
        LearningCollectionProjection(
          code: code,
          verticalCode: row.read<String>('vertical_code'),
          trackCode: row.read<String>('track_code'),
          title: row.read<String>('title'),
          description: row.read<String>('description'),
          sortOrder: row.read<int>('sort_order'),
          active: row.read<int>('active') == 1,
          members: await _readMembers(version, code),
        ),
      );
    }
    return result;
  }

  Future<List<LearningCollectionMember>> _readMembers(
    int version,
    String collectionCode,
  ) async {
    final rows = await _database
        .customSelect(
          '''
      SELECT position, member_type,
             content_code, content_type, content_revision, content_checksum,
             practice_test_code, practice_test_revision, practice_test_checksum
      FROM learning_collection_member_reads
      WHERE content_version = ? AND collection_code = ?
      ORDER BY position
      ''',
          variables: [Variable<int>(version), Variable<String>(collectionCode)],
        )
        .get();

    return [for (final row in rows) _member(row)];
  }

  LearningCollectionMember _member(QueryRow row) {
    final type = LearningCollectionMemberType.fromWireName(
      row.read<String>('member_type'),
    );
    final position = row.read<int>('position');
    return switch (type) {
      LearningCollectionMemberType.content => LearningCollectionMember.content(
        position: position,
        content: ContentRevisionRef(
          contentCode: row.read<String>('content_code'),
          contentType: _contentType(row.read<String>('content_type')),
          revision: row.read<int>('content_revision'),
          checksum: row.read<String>('content_checksum'),
        ),
      ),
      LearningCollectionMemberType.practiceTest =>
        LearningCollectionMember.practiceTest(
          position: position,
          practiceTest: PracticeTestRevisionRef(
            practiceTestCode: row.read<String>('practice_test_code'),
            revision: row.read<int>('practice_test_revision'),
            checksum: row.read<String>('practice_test_checksum'),
          ),
        ),
    };
  }

  ContentType _contentType(String value) {
    for (final type in ContentType.values) {
      if (type.name == value) return type;
    }
    throw FormatException('Unsupported persisted content type $value.');
  }

  Future<VerticalCataloguePresentation> _readPresentation(int version) async {
    final rows = await _database
        .customSelect(
          '''
      SELECT mode, show_featured, show_see_all, featured_section_code
      FROM vertical_presentation_reads
      WHERE content_version = ?
      ''',
          variables: [Variable<int>(version)],
        )
        .get();
    if (rows.length != 1) {
      throw StateError(
        'CURRENT snapshot must contain exactly one presentation.',
      );
    }
    final row = rows.single;
    return VerticalCataloguePresentation(
      mode: VerticalCataloguePresentationMode.fromWireName(
        row.read<String>('mode'),
      ),
      showFeatured: row.read<int>('show_featured') == 1,
      showSeeAll: row.read<int>('show_see_all') == 1,
      featuredSectionCode: row.readNullable<String>('featured_section_code'),
    );
  }
}
