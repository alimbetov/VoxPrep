import '../../domain/content_item.dart';

abstract interface class ContentRepository {
  List<ContentItem> get all;

  ContentItem? byCode(String code);
}
