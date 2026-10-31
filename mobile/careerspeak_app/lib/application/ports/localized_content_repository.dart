import '../content_delivery/localized_content_resolution.dart';
import '../result/result.dart';
import '../../domain/content_identity.dart';

abstract interface class LocalizedContentRepository {
  Future<Result<ResolvedLocalizedContent?>> resolve({
    required ContentIdentity identity,
    required int contentRevision,
    required String requestedLocale,
  });
}
