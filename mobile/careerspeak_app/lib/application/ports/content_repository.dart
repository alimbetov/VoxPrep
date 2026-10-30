import '../../domain/content_identity.dart';
import '../../domain/content_item.dart';
import '../query/content_query.dart';
import '../query/page.dart';
import '../result/result.dart';

abstract interface class ContentRepository {
  Stream<Result<Page<ContentItem>>> watchContent(ContentQuery query);

  Future<Result<ContentItem?>> getByIdentity(ContentIdentity identity);
}
