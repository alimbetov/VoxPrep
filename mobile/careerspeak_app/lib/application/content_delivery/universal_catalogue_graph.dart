import 'learning_vertical.dart';
import 'product_catalog.dart';
import 'vertical_catalogue_presentation.dart';

final class UniversalCatalogueGraph {
  factory UniversalCatalogueGraph({
    required Iterable<VerticalSectionProjection> sections,
    required Iterable<LearningVerticalProjection> verticals,
    required Iterable<LearningGoalProjection> goals,
    required Iterable<LearningTrackProjection> tracks,
    required Iterable<LearningCollectionProjection> collections,
    required VerticalCataloguePresentation presentation,
  }) {
    final sectionList = List<VerticalSectionProjection>.unmodifiable(sections);
    final verticalList = List<LearningVerticalProjection>.unmodifiable(
      verticals,
    );
    final goalList = List<LearningGoalProjection>.unmodifiable(goals);
    final trackList = List<LearningTrackProjection>.unmodifiable(tracks);
    final collectionList = List<LearningCollectionProjection>.unmodifiable(
      collections,
    );

    _requireUnique(sectionList.map((item) => item.code), 'sections');
    _requireUnique(verticalList.map((item) => item.code), 'verticals');
    _requireUnique(goalList.map((item) => item.code), 'goals');
    _requireUnique(trackList.map((item) => item.code), 'tracks');
    _requireUnique(collectionList.map((item) => item.code), 'collections');

    final sectionsByCode = <String, VerticalSectionProjection>{
      for (final item in sectionList) item.code: item,
    };
    final verticalsByCode = <String, LearningVerticalProjection>{
      for (final item in verticalList) item.code: item,
    };
    final goalsByCode = <String, LearningGoalProjection>{
      for (final item in goalList) item.code: item,
    };
    final tracksByCode = <String, LearningTrackProjection>{
      for (final item in trackList) item.code: item,
    };

    for (final vertical in verticalList) {
      if (!sectionsByCode.containsKey(vertical.sectionCode)) {
        throw FormatException(
          'Vertical ${vertical.code} references missing section '
          '${vertical.sectionCode}.',
        );
      }
    }

    for (final goal in goalList) {
      if (!verticalsByCode.containsKey(goal.verticalCode)) {
        throw FormatException(
          'Goal ${goal.code} references missing vertical ${goal.verticalCode}.',
        );
      }
    }

    for (final track in trackList) {
      final goal = goalsByCode[track.goalCode];
      if (goal == null) {
        throw FormatException(
          'Track ${track.code} references missing goal ${track.goalCode}.',
        );
      }
      if (goal.verticalCode != track.verticalCode) {
        throw FormatException(
          'Track ${track.code} crosses vertical ownership: '
          '${track.verticalCode} != ${goal.verticalCode}.',
        );
      }
    }

    for (final collection in collectionList) {
      final track = tracksByCode[collection.trackCode];
      if (track == null) {
        throw FormatException(
          'Collection ${collection.code} references missing track '
          '${collection.trackCode}.',
        );
      }
      if (track.verticalCode != collection.verticalCode) {
        throw FormatException(
          'Collection ${collection.code} crosses vertical ownership: '
          '${collection.verticalCode} != ${track.verticalCode}.',
        );
      }
    }

    final featuredSectionCode = presentation.featuredSectionCode;
    if (featuredSectionCode != null &&
        !sectionsByCode.containsKey(featuredSectionCode)) {
      throw FormatException(
        'Vertical presentation references missing featured section '
        '$featuredSectionCode.',
      );
    }

    return UniversalCatalogueGraph._(
      sections: sectionList,
      verticals: verticalList,
      goals: goalList,
      tracks: trackList,
      collections: collectionList,
      presentation: presentation,
    );
  }

  const UniversalCatalogueGraph._({
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

void _requireUnique(Iterable<String> values, String field) {
  final seen = <String>{};
  for (final value in values) {
    if (!seen.add(value)) {
      throw FormatException('$field contain duplicate code $value.');
    }
  }
}
