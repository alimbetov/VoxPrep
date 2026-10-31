import 'catalogue_revision_ref.dart';

final class CataloguePayload {
  CataloguePayload({
    required this.ref,
    required Iterable<Object> items,
    required Map<String, Object?> wireJson,
  }) : items = List<Object>.unmodifiable(items),
       wireJson = Map<String, Object?>.unmodifiable(wireJson);

  final CatalogueRevisionRef ref;
  final List<Object> items;
  final Map<String, Object?> wireJson;
}
