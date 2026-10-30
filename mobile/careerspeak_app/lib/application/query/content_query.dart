import '../../domain/content_item.dart';
import 'page.dart';

class ContentQuery {
  const ContentQuery({
    this.search,
    this.types = const {},
    this.category,
    this.level,
    this.page = const PageRequest(),
  });

  final String? search;
  final Set<ContentType> types;
  final String? category;
  final String? level;
  final PageRequest page;
}
