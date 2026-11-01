import '../../domain/content_identity.dart';
import '../../domain/last_opened_content.dart';
import '../result/result.dart';

abstract interface class LastOpenedContentRepository {
  Future<Result<LastOpenedContent?>> getLastOpenedContent();

  Future<Result<LastOpenedContent>> recordOpened({
    required ContentIdentity identity,
    required int contentRevision,
  });
}
