import 'learning_vertical.dart';
import 'product_catalog.dart';
import 'vertical_catalogue_presentation.dart';

final class UniversalVerticalCatalogueGraph {
  factory UniversalVerticalCatalogueGraph({
    required Iterable<VerticalSectionProjection> sections,
    required Iterable<LearningVerticalProjection> verticals,
    required Iterable<LearningGoalProjection> goals,
    required Iterable<LearningTrackProjection> tracks,
    required Iterable<LearningCollectionProjection> collections,
    required VerticalCataloguePresentation presentation,
  }) {
    final frozenSections = List<VerticalSectionProjection>.unmodifiable(sections);
    final frozenVerticals = List<LearningVerticalProjection>.unmodifiable(
      verticals,
    );
    final frozenGoals = List<LearningGoalProjection>.unmodifiable(goals);
    final frozenTracks = List<LearningTrackProjection>.unmodifiable(tracks);
    final frozenCollections = List<LearningCollectionProjection>.unmodifiable(
      collections,
    );

    final sectionByCode = _indexByCode(
      frozenSections,
      (item) => item.code,
      'sections',
    );
    final verticalByCode = _indexByCode(
      frozenVerticals,
      (item) => item.code,
      'verticals',
    );
    final goalByCode = _indexByCode(
      frozenGoals,
      (item) => item.code,
      'goals',
    );
    final trackByCode = _indexByCode(
      frozenTracks,
      (item) => item.code,
      'tracks',
    );
    _requireUniqueCodes(
      frozenCollections.map((item) => item.code),
      'collections',
    );

    for (final vertical in frozenVerticals) {
      if (!sectionByCode.containsKey(vertical.sectionCode)) {
        throw ArgumentError.value(
          vertical.sectionCode,
          'verticals',
          'vertical ${vertical.code} references an unknown section',
        );
      }
    }

    final featuredSectionCode = presentation.featuredSectionCode;
    if (featuredSectionCode != null &&
        !sectionByCode.containsKey(featuredSectionCode)) {
      throw ArgumentError.value(
        featuredSectionCode,
        'presentation',
        'references an unknown featured section',
      );
    }

    for (final goal in frozenGoals) {
      if (!verticalByCode.containsKey(goal.verticalCode)) {
        throw ArgumentError.value(
          goal.verticalCode,
          'goals',
          'goal ${goal.code} references an unknown vertical',
        );
      }
    }

    for (final track in frozenTracks) {
      if (!verticalByCode.containsKey(track.verticalCode)) {
        throw ArgumentError.value(
          track.verticalCode,
          'tracks',
          'track ${track.code} references an unknown vertical',
        );
      }
      final goal = goalByCode[track.goalCode];
      if (goal == null) {
        throw ArgumentError.value(
          track.goalCode,
          'tracks',
          'track ${track.code} references an unknown goal',
        );
      }
      if (goal.verticalCode != track.verticalCode) {
        throw ArgumentError.value(
          track.verticalCode,
          'tracks',
          'track ${track.code} crosses vertical ownership boundary',
        );
      }
    }

    for (final collection in frozenCollections) {
      if (!verticalByCode.containsKey(collection.verticalCode)) {
        throw ArgumentError.value(
          collection.verticalCode,
          'collections',
          'collection ${collection.code} references an unknown vertical',
        );
      }
      final track = trackByCode[collection.trackCode];
      if (track == null) {
        throw ArgumentError.value(
          collection.trackCode,
          'collections',
          'collection ${collection.code} references an unknown track',
        );
      }
      if (track.verticalCode != collection.verticalCode) {
        throw ArgumentError.value(
          collection.verticalCode,
          'collections',
          'collection ${collection.code} crosses vertical ownership boundary',
        );
      }
    }

    return UniversalVerticalCatalogueGraph._(
      sections: frozenSections,
      verticals: frozenVerticals,
      goals: frozenGoals,
      tracks: frozenTracks,
      collections: frozenCollections,
      presentation: presentation,
    );
  }

  const UniversalVerticalCatalogueGraph._({
    required this.sections,
    required this.verticals,
    required this.goals,
    required this.tracks,
    required this.collections,
    required this.presentation,
  });

  final List<VerticalSectionProjection> sections;
  final List<LearningVerticalProjection> verticals;
  final List<LearningGoalProjection> goals;
  final List<LearningTrackProjection> tracks;
  final List<LearningCollectionProjection> collections;
  final VerticalCataloguePresentation presentation;
}

Map<String, T> _indexByCode<T>(
  Iterable<T> items,
  String Function(T item) codeOf,
  String fieldName,
) {
  final result = <String, T>{};
  for (final item in items) {
    final code = codeOf(item);
    if (result.containsKey(code)) {
      throw ArgumentError.value(code, fieldName, 'contains duplicate code');
    }
    result[code] = item;
  }
  return Map<String, T>.unmodifiable(result);
}

void _requireUniqueCodes(Iterable<String> codes, String fieldName) {
  final seen = <String>{};
  for (final code in codes) {
    if (!seen.add(code)) {
      throw ArgumentError.value(code, fieldName, 'contains duplicate code');
    }
  }
}
