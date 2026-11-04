import '../access/access_snapshot.dart';
import '../content_delivery/product_catalog.dart';
import '../ports/access_snapshot_repository.dart';
import '../ports/api_client.dart';
import '../result/result.dart';

/// Reconciles the cached purchase snapshot with server-authoritative ownership.
/// Offline errors preserve the last local snapshot; online FREE clears stale FULL.
final class EntitlementStatusRefreshService {
  const EntitlementStatusRefreshService({
    required ApiClient apiClient,
    required AccessSnapshotRepository repository,
  }) : _apiClient = apiClient,
       _repository = repository;

  final ApiClient _apiClient;
  final AccessSnapshotRepository _repository;

  Future<Result<bool>> refresh() async {
    final result = await _apiClient.send(
      ApiRequest(
        method: ApiMethod.get,
        path: '/api/v1/purchases/entitlement',
        authentication: ApiAuthentication.installation,
      ),
    );
    if (result case FailureResult<ApiResponse>(:final failure)) {
      return FailureResult<bool>(failure);
    }

    final response = (result as Success<ApiResponse>).value;
    if (response.statusCode != 200) {
      return const FailureResult<bool>(
        ApplicationFailure(
          code: 'ENTITLEMENT_STATUS_UNAVAILABLE',
          message: 'Store entitlement could not be refreshed.',
          retryable: true,
        ),
      );
    }
    final body = response.jsonBody;
    if (body is! Map<String, Object?> ||
        body.length != 3 ||
        !body.containsKey('verified') ||
        !body.containsKey('accessLevel') ||
        !body.containsKey('verifiedAt')) {
      return _invalid();
    }

    final verified = body['verified'];
    final level = body['accessLevel'];
    final rawDate = body['verifiedAt'];
    if (verified is! bool ||
        level is! String ||
        (verified && (level != 'FULL' || rawDate is! String)) ||
        (!verified && (level != 'FREE' || rawDate != null))) {
      return _invalid();
    }

    final DateTime verifiedAt;
    if (verified) {
      final parsed = DateTime.tryParse(rawDate as String);
      if (parsed == null || !parsed.isUtc) return _invalid();
      verifiedAt = parsed;
    } else {
      verifiedAt = DateTime.now().toUtc();
    }

    final saved = await _repository.replace(
      AccessSnapshot(
        accessLevel: verified ? AccessLevel.full : AccessLevel.free,
        verifiedAt: verifiedAt,
        source: AccessSnapshotSource.backendVerified,
      ),
    );
    if (saved case FailureResult<void>(:final failure)) {
      return FailureResult<bool>(failure);
    }
    return const Success<bool>(true);
  }

  static FailureResult<bool> _invalid() {
    return const FailureResult<bool>(
      ApplicationFailure(
        code: 'ENTITLEMENT_STATUS_INVALID',
        message: 'Server entitlement response is inconsistent.',
      ),
    );
  }
}
