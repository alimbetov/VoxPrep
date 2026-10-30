class PageRequest {
  const PageRequest({
    this.limit = 50,
    this.cursor,
  }) : assert(limit > 0 && limit <= 200);

  final int limit;
  final String? cursor;
}

class Page<T> {
  const Page({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<T> items;
  final bool hasMore;
  final String? nextCursor;
}
