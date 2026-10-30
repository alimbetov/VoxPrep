import '../../application/ports/content_repository.dart';
import '../../application/query/content_query.dart';
import '../../application/query/page.dart';
import '../../application/result/result.dart';
import '../../domain/content_item.dart';

class MockContentRepository implements ContentRepository {
  const MockContentRepository();

  static const _items = <ContentItem>[
    ContentItem(
      code: 'JAVA_DI_001',
      type: ContentType.interview,
      title: 'Dependency Injection',
      subtitle: 'Java Backend · Senior interview',
      description:
          'Explain dependency injection, why it improves testability, and how Spring resolves dependencies.',
      category: 'Java Backend',
      level: 'Senior',
      minutes: 8,
    ),
    ContentItem(
      code: 'JAVA_CONCURRENCY_001',
      type: ContentType.interview,
      title: 'ConcurrentHashMap',
      subtitle: 'Java · Concurrency',
      description:
          'Describe the concurrency guarantees of ConcurrentHashMap and compare it with HashMap.',
      category: 'Java Backend',
      level: 'Senior',
      minutes: 10,
    ),
    ContentItem(
      code: 'VOCAB_SIGNIFICANT',
      type: ContentType.vocabulary,
      title: 'significant',
      subtitle: '/sɪɡˈnɪfɪkənt/ · adjective · B2',
      description:
          'Sufficiently great or important to be worthy of attention; noteworthy.',
      category: 'Vocabulary',
      level: 'B2',
      minutes: 3,
    ),
    ContentItem(
      code: 'VOCAB_SUBSTANTIAL',
      type: ContentType.vocabulary,
      title: 'substantial',
      subtitle: '/səbˈstænʃəl/ · adjective · C1',
      description: 'Large in amount, value or importance.',
      category: 'Vocabulary',
      level: 'C1',
      minutes: 3,
    ),
    ContentItem(
      code: 'IELTS_ENV_001',
      type: ContentType.topic,
      title: 'Urban Environment',
      subtitle: 'IELTS Speaking · Part 3',
      description:
          'Discuss how cities can reduce congestion and improve quality of life.',
      category: 'IELTS',
      level: 'B2-C1',
      minutes: 12,
    ),
    ContentItem(
      code: 'SHADOW_SYSTEM_DESIGN_001',
      type: ContentType.shadowing,
      title: 'Explaining System Design',
      subtitle: 'Shadowing · Software Engineering',
      description:
          'Practice a concise explanation of scalability, caching and database trade-offs.',
      category: 'Professional English',
      level: 'C1',
      minutes: 7,
    ),
    ContentItem(
      code: 'PHRASE_CLARIFY_001',
      type: ContentType.phrase,
      title: 'Could you clarify what you mean by…?',
      subtitle: 'Interview phrase · Clarification',
      description:
          'A professional phrase for requesting clarification before answering.',
      category: 'Phrase Bank',
      level: 'B1+',
      minutes: 2,
    ),
  ];

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
  Future<Result<ContentItem?>> getByCode(String code) async {
    for (final item in _items) {
      if (item.code == code) return Success(item);
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
