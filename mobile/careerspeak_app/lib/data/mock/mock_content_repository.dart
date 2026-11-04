import '../../application/ports/content_repository.dart';
import '../../application/query/content_query.dart';
import '../../application/query/page.dart';
import '../../application/result/result.dart';
import '../../domain/content_identity.dart';
import '../../domain/content_item.dart';
import 'generated_demo_content.dart';

class MockContentRepository implements ContentRepository {
  const MockContentRepository();

  static const _items = generatedDemoContentItems;

  @override
  Stream<Result<Page<ContentItem>>> watchContent(ContentQuery query) {
    final normalizedSearch = query.search?.trim().toLowerCase();
    final filtered = _items
        .where((item) {
          if (normalizedSearch != null && normalizedSearch.isNotEmpty) {
            final searchable =
                '${item.title} ${item.subtitle} ${item.description}'
                    .toLowerCase();
            if (!searchable.contains(normalizedSearch)) return false;
          }
          if (query.types.isNotEmpty && !query.types.contains(item.type)) {
            return false;
          }
          if (query.category != null && item.category != query.category) {
            return false;
          }
          if (query.level != null && item.level != query.level) {
            return false;
          }
          return true;
        })
        .toList(growable: false);

    return Stream.value(Success(_page(filtered, query.page)));
  }

  @override
  Future<Result<ContentItem?>> getByIdentity(ContentIdentity identity) async {
    for (final item in _items) {
      if (item.code == identity.code && item.type == identity.type) {
        return Success(item);
      }
    }
    return const Success(null);
  }
}

Page<ContentItem> _page(List<ContentItem> items, PageRequest request) {
  final cursorIndex = request.cursor == null
      ? -1
      : items.indexWhere((item) => item.code == request.cursor);
  final start = cursorIndex < 0 ? 0 : cursorIndex + 1;
  final end = start + request.limit > items.length
      ? items.length
      : start + request.limit;
  final pageItems = items.sublist(start, end);
  final hasMore = end < items.length;

  return Page(
    items: pageItems,
    hasMore: hasMore,
    nextCursor: hasMore && pageItems.isNotEmpty ? pageItems.last.code : null,
  );
}
