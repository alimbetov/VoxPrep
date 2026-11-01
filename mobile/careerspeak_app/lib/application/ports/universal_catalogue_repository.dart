import '../content_delivery/universal_catalogue_graph.dart';
import '../result/result.dart';

final class CurrentUniversalCatalogueSnapshot {
  const CurrentUniversalCatalogueSnapshot({
    required this.contentVersion,
    required this.graph,
  });

  final int contentVersion;
  final UniversalCatalogueGraph graph;
}

abstract interface class UniversalCatalogueRepository {
  /// Reads only the learner-visible graph selected by the single durable
  /// content_manifest_states.current_content_version pointer.
  Future<Result<CurrentUniversalCatalogueSnapshot?>> readCurrent();
}
