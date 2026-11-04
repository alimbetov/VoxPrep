import 'package:careerspeak_app/application/access/access_snapshot.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/ports/access_snapshot_repository.dart';
import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/entitlement_status_refresh_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final verifiedAt = DateTime.utc(2026, 11, 4);

  test('online refund clears an old locally stored FULL unlock', () async {
    final store = _MemoryAccessStore(
      AccessSnapshot(
        accessLevel: AccessLevel.full,
        verifiedAt: verifiedAt,
        source: AccessSnapshotSource.backendVerified,
      ),
    );
    final api = _FakeApiClient(
      _response(<String, Object?>{
        'verified': false,
        'accessLevel': 'FREE',
        'verifiedAt': null,
      }),
    );
    final service = EntitlementStatusRefreshService(
      apiClient: api,
      repository: store,
    );
    final outcome = await service.refresh();

    expect(outcome, isA<Success<bool>>());
    expect(store.snapshot?.accessLevel, AccessLevel.free);
    expect(api.request?.path, '/api/v1/purchases/entitlement');
    expect(api.request?.authentication, ApiAuthentication.installation);
  });

  test('valid backend entitlement grants FULL with server timestamp', () async {
    final store = _MemoryAccessStore(null);
    final service = EntitlementStatusRefreshService(
      apiClient: _FakeApiClient(
        _response(<String, Object?>{
          'verified': true,
          'accessLevel': 'FULL',
          'verifiedAt': '2026-11-04T00:00:00Z',
        }),
      ),
      repository: store,
    );

    expect(await service.refresh(), isA<Success<bool>>());
    expect(store.snapshot?.accessLevel, AccessLevel.full);
    expect(store.snapshot?.verifiedAt, verifiedAt);
  });

  test('offline network error preserves last paid local snapshot', () async {
    final store = _MemoryAccessStore(
      AccessSnapshot(
        accessLevel: AccessLevel.full,
        verifiedAt: verifiedAt,
        source: AccessSnapshotSource.backendVerified,
      ),
    );
    final service = EntitlementStatusRefreshService(
      apiClient: _FakeApiClient(
        const FailureResult<ApiResponse>(
          ApplicationFailure(
            code: 'OFFLINE',
            message: 'No network',
            retryable: true,
          ),
        ),
      ),
      repository: store,
    );
    expect(await service.refresh(), isA<FailureResult<bool>>());
    expect(store.snapshot?.accessLevel, AccessLevel.full);
  });

  test('malformed or contradictory server response never grants FULL', () async {
    final store = _MemoryAccessStore(null);
    final service = EntitlementStatusRefreshService(
      apiClient: _FakeApiClient(
        _response(<String, Object?>{
          'verified': false,
          'accessLevel': 'FULL',
          'verifiedAt': null,
        }),
      ),
      repository: store,
    );
    expect(await service.refresh(), isA<FailureResult<bool>>());
    expect(store.snapshot, isNull);
  });
}

Result<ApiResponse> _response(Map<String, Object?> json) {
  return Success<ApiResponse>(
    ApiResponse(
      statusCode: 200,
      headers: const <String, String>{},
      jsonBody: json,
    ),
  );
}

final class _FakeApiClient implements ApiClient {
  _FakeApiClient(this.result);
  final Result<ApiResponse> result;
  ApiRequest? request;

  @override
  Future<Result<ApiResponse>> send(ApiRequest value) async {
    request = value;
    return result;
  }
}

final class _MemoryAccessStore implements AccessSnapshotRepository {
  _MemoryAccessStore(this.snapshot);
  AccessSnapshot? snapshot;

  @override
  Future<Result<AccessSnapshot?>> read() async {
    return Success<AccessSnapshot?>(snapshot);
  }

  @override
  Future<Result<void>> replace(AccessSnapshot value) async {
    snapshot = value;
    return const Success<void>(null);
  }
}
